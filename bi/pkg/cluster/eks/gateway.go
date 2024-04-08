package eks

import (
	"encoding/json"
	"fmt"
	"net"
	"net/netip"
	"strings"

	"bi/pkg/cluster/util"
	"bi/pkg/wireguard"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/ec2"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/iam"
	pvpc "github.com/pulumi/pulumi-aws/sdk/v6/go/aws/vpc"
	"github.com/pulumi/pulumi-cloudinit/sdk/go/cloudinit"
	"github.com/pulumi/pulumi-tls/sdk/v5/go/tls"
	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

type gatewayConfig struct {
	// config
	baseName         string
	wireguardName    string
	vpcCidrBlock     *net.IPNet
	gatewayCIDRBlock *net.IPNet
	generateSSHKey   bool
	instanceType     string
	port             int
	volumeType       string
	volumeSize       int

	// from outputs
	vpcID            string
	publicSubnetIDs  []string
	privateSubnetIDs []string

	// state
	securityGroupID, iamProfileID, ec2InstanceID pulumi.IDOutput
	privateKey                                   *tls.PrivateKey
	keypair                                      *ec2.KeyPair
	publicIP                                     pulumi.StringOutput
	wgGateway                                    *wireguard.Gateway
	wgClient                                     *wireguard.Client
}

func (g *gatewayConfig) withConfig(cfg *util.PulumiConfig) error {
	g.baseName = cfg.Cluster.Name
	g.gatewayCIDRBlock = cfg.Gateway.CIDRBlock
	g.generateSSHKey = cfg.Gateway.GenerateSSHKey
	g.instanceType = cfg.Gateway.InstanceType
	g.port = cfg.Gateway.Port
	g.volumeSize = cfg.Gateway.VolumeSize
	g.volumeType = cfg.Gateway.VolumeType
	g.vpcCidrBlock = cfg.VPC.CIDRBlock
	g.wireguardName = g.baseName + "-wireguard"

	return nil
}

func (g *gatewayConfig) withOutputs(outputs map[string]auto.OutputMap) error {

	if outputs["vpc"]["vpcID"].Value != nil {
		g.vpcID = outputs["vpc"]["vpcID"].Value.(string)
	}

	if outputs["vpc"]["publicSubnetIDs"].Value != nil {
		g.publicSubnetIDs = util.ToStringSlice(outputs["vpc"]["publicSubnetIDs"].Value)
	}

	if outputs["vpc"]["privateSubnetIDs"].Value != nil {
		g.privateSubnetIDs = util.ToStringSlice(outputs["vpc"]["privateSubnetIDs"].Value)
	}

	return nil
}

func (g *gatewayConfig) run(ctx *pulumi.Context) error {
	for _, fn := range []func(*pulumi.Context) error{
		g.buildWireGuardConfig,
		g.buildSecurityGroup,
		g.buildKeyPair,
		g.buildIAMProfile,
		g.buildEC2Instance,
		g.buildEIP,
	} {
		if err := fn(ctx); err != nil {
			return err
		}
	}

	ctx.Export("publicIP", g.publicIP)
	ctx.Export("publicPort", pulumi.Int(g.port))
	ctx.Export("securityGroupID", g.securityGroupID)

	ctx.Export("wgGatewayPrivateKey", pulumi.String(g.wgGateway.PrivateKey))
	ctx.Export("wgGatewayAddress", pulumi.String(g.wgGateway.Address.String()))

	ctx.Export("wgClientPrivateKey", pulumi.String(g.wgClient.PrivateKey))
	ctx.Export("wgClientAddress", pulumi.String(g.wgClient.Address.String()))

	if g.generateSSHKey {
		ctx.Export("sshPrivateKey", g.privateKey.PrivateKeyOpenssh)
	}

	return nil
}

type sgRule struct {
	port  pulumi.Int
	proto pulumi.String
	cidr  pulumi.String
}

func (g *gatewayConfig) buildSecurityGroup(ctx *pulumi.Context) error {
	sg, err := ec2.NewSecurityGroup(ctx, g.wireguardName, &ec2.SecurityGroupArgs{
		Name:        pulumi.String(g.wireguardName),
		Description: pulumi.String("Allow wireguard traffic"),
		VpcId:       pulumi.String(g.vpcID),
		Tags:        pulumi.StringMap{"Name": pulumi.String(g.wireguardName)},
	})
	if err != nil {
		return err
	}
	g.securityGroupID = sg.ID()

	allCidr, wgCidr, vpcCidr :=
		pulumi.String("0.0.0.0/0"),
		pulumi.String(g.gatewayCIDRBlock.String()),
		pulumi.String(g.vpcCidrBlock.String())

	rules := map[string]sgRule{
		"wg-all":   {port: pulumi.Int(g.port), proto: P_STR_UDP, cidr: allCidr},
		"dns-wg":   {port: pulumi.Int(53), proto: P_STR_UDP, cidr: wgCidr},
		"icmp-wg":  {port: pulumi.Int(-1), proto: P_STR_ICMP, cidr: wgCidr},
		"icmp-vpc": {port: pulumi.Int(-1), proto: P_STR_ICMP, cidr: vpcCidr},
	}

	if g.generateSSHKey {
		rules["ssh-all"] = sgRule{port: pulumi.Int(22), proto: P_STR_TCP, cidr: allCidr}
	}

	for name, rule := range rules {
		_, err = pvpc.NewSecurityGroupIngressRule(ctx, fmt.Sprintf("%s-%s", g.wireguardName, name), &pvpc.SecurityGroupIngressRuleArgs{
			SecurityGroupId: sg.ID(),
			FromPort:        rule.port,
			ToPort:          rule.port,
			IpProtocol:      rule.proto,
			CidrIpv4:        rule.cidr,
			Tags:            pulumi.StringMap{"Name": pulumi.String(name)},
		}, pulumi.Parent(sg))
		if err != nil {
			return err
		}
	}

	_, err = pvpc.NewSecurityGroupEgressRule(ctx, g.wireguardName, &pvpc.SecurityGroupEgressRuleArgs{
		SecurityGroupId: sg.ID(),
		IpProtocol:      pulumi.String("-1"),
		CidrIpv4:        allCidr,
		Tags:            pulumi.StringMap{"Name": pulumi.String("egress-all")},
	}, pulumi.Parent(sg))
	if err != nil {
		return err
	}

	return nil
}

func (g *gatewayConfig) buildKeyPair(ctx *pulumi.Context) error {
	if !g.generateSSHKey {
		return nil
	}

	pk, err := tls.NewPrivateKey(ctx, g.baseName, &tls.PrivateKeyArgs{
		Algorithm: pulumi.String("ED25519"),
	})
	if err != nil {
		return err
	}
	g.privateKey = pk

	kp, err := ec2.NewKeyPair(ctx, g.baseName, &ec2.KeyPairArgs{
		KeyNamePrefix: pulumi.StringPtr(g.baseName),
		PublicKey:     pk.PublicKeyOpenssh,
	})
	if err != nil {
		return err
	}
	g.keypair = kp

	return nil
}

func (g *gatewayConfig) buildIAMProfile(ctx *pulumi.Context) error {
	ssmPolicy, err := iam.LookupPolicy(ctx, &iam.LookupPolicyArgs{
		Name: pulumi.StringRef("AmazonSSMManagedInstanceCore"),
	})
	if err != nil {
		return err
	}

	instanceAssumeRolePolicy, err := iam.GetPolicyDocument(ctx, &iam.GetPolicyDocumentArgs{
		Statements: []iam.GetPolicyDocumentStatement{
			{
				Sid:     pulumi.StringRef("WireguardInstanceAssumeRole"),
				Actions: []string{"sts:AssumeRole"},
				Principals: []iam.GetPolicyDocumentStatementPrincipal{
					{
						Type:        "Service",
						Identifiers: []string{"ec2.amazonaws.com"},
					},
				},
			},
		},
	})
	if err != nil {
		return err
	}

	role, err := iam.NewRole(ctx, g.wireguardName, &iam.RoleArgs{
		Name:                pulumi.String(g.wireguardName),
		AssumeRolePolicy:    pulumi.String(instanceAssumeRolePolicy.Json),
		ManagedPolicyArns:   pulumi.ToStringArray([]string{ssmPolicy.Arn}),
		ForceDetachPolicies: P_BOOL_PTR_TRUE,
		Tags:                pulumi.StringMap{"Name": pulumi.String(g.wireguardName)},
	})
	if err != nil {
		return err
	}

	profile, err := iam.NewInstanceProfile(ctx, g.wireguardName, &iam.InstanceProfileArgs{
		Role: role.Name,
		Tags: pulumi.StringMap{"Name": pulumi.String(g.wireguardName)},
	})
	if err != nil {
		return err
	}
	g.iamProfileID = profile.ID()

	return nil
}

func (g *gatewayConfig) buildEC2Instance(ctx *pulumi.Context) error {
	cc, err := g.buildCloudConfig()
	if err != nil {
		return err
	}

	ccBytes, err := json.Marshal(&cc)
	if err != nil {
		return err
	}

	conf, err := cloudinit.NewConfig(ctx, g.wireguardName, &cloudinit.ConfigArgs{
		Gzip:         P_BOOL_PTR_FALSE,
		Base64Encode: P_BOOL_PTR_FALSE,

		Parts: cloudinit.ConfigPartArray{
			&cloudinit.ConfigPartArgs{
				Filename:    pulumi.String("cloud-config.yaml"),
				ContentType: pulumi.String("text/cloud-config"),
				Content:     pulumi.String(string(ccBytes)),
			},
		},
	})
	if err != nil {
		return err
	}

	ami, err := ec2.LookupAmi(ctx, &ec2.LookupAmiArgs{
		Filters: []ec2.GetAmiFilter{
			{Name: "name", Values: []string{"ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"}},
			{Name: "virtualization-type", Values: []string{"hvm"}},
		},
		MostRecent: pulumi.BoolRef(true),
		Owners:     []string{"099720109477"}, // Canonical
	})
	if err != nil {
		return err
	}

	var keyName pulumi.StringPtrInput = nil
	if g.generateSSHKey {
		keyName = g.keypair.KeyName
	}

	instance, err := ec2.NewInstance(ctx, g.wireguardName, &ec2.InstanceArgs{
		Ami:                 pulumi.String(ami.Id),
		SubnetId:            pulumi.String(g.publicSubnetIDs[0]),
		InstanceType:        pulumi.String(g.instanceType),
		VpcSecurityGroupIds: pulumi.StringArray{g.securityGroupID},
		IamInstanceProfile:  g.iamProfileID,
		KeyName:             keyName,
		Tags:                pulumi.StringMap{"Name": pulumi.String(g.wireguardName)},
		UserData:            conf.Rendered,
		MetadataOptions: ec2.InstanceMetadataOptionsArgs{
			HttpTokens: pulumi.String("required"),
		},

		RootBlockDevice: ec2.InstanceRootBlockDeviceArgs{
			VolumeType: pulumi.String(g.volumeType),
			VolumeSize: pulumi.Int(g.volumeSize),
		},
	}, pulumi.ReplaceOnChanges([]string{"userData"}), pulumi.IgnoreChanges([]string{"ami"}))
	if err != nil {
		return err
	}

	g.ec2InstanceID = instance.ID()

	return nil
}

func (g *gatewayConfig) buildEIP(ctx *pulumi.Context) error {
	eip, err := ec2.NewEip(ctx, g.wireguardName, &ec2.EipArgs{
		Tags: pulumi.StringMap{"Name": pulumi.String(g.wireguardName)},
	})
	if err != nil {
		return err
	}

	g.publicIP = eip.PublicIp

	_, err = ec2.NewEipAssociation(ctx, g.wireguardName, &ec2.EipAssociationArgs{
		InstanceId:   g.ec2InstanceID,
		AllocationId: eip.ID(),
	})
	if err != nil {
		return err
	}

	return nil
}

func (g *gatewayConfig) buildWireGuardConfig(ctx *pulumi.Context) error {
	var err error
	g.wgGateway, err = wireguard.NewGateway(uint16(g.port), g.gatewayCIDRBlock)
	if err != nil {
		return fmt.Errorf("failed to create wireguard gateway: %w", err)
	}

	// Route53 static resolver addresses.
	// See: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html#AmazonDNS
	g.wgGateway.DNSServers = []netip.Addr{
		netip.MustParseAddr("169.254.169.253"),
		netip.MustParseAddr("fd00:ec2::253"),
	}

	g.wgGateway.PostUp = []string{
		"iptables -A FORWARD -i wg0 -j ACCEPT",
		"iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE",
	}

	g.wgGateway.PreDown = []string{
		"iptables -D FORWARD -i wg0 -j ACCEPT",
		"iptables -t nat -D POSTROUTING -o ens5 -j MASQUERADE",
	}

	g.wgClient, err = g.wgGateway.NewClient("installer")
	if err != nil {
		return fmt.Errorf("failed to create wireguard client for installer: %w", err)
	}

	return nil
}

func (g *gatewayConfig) buildCloudConfig() (*cloudConfig, error) {
	var sb strings.Builder
	if err := g.wgGateway.WriteConfig(&sb); err != nil {
		return nil, err
	}

	return &cloudConfig{
		PackageRebootIfRequired: true,
		PackageUpdate:           true,
		PackageUpgrade:          true,
		Packages: []string{
			"apt-transport-https",
			"ca-certificates",
			"net-tools",
			"software-properties-common",
			"ufw",
		},
		RunCmd: [][]string{{"sudo", "sysctl", "-p"}},
		Snap: snap{Commands: [][]string{
			{"snap", "install", "amazon-ssm-agent", "--classic"},
			{"snap", "start", "amazon-ssm-agent"},
		}},
		Wireguard: wg{Interfaces: []wgInterface{{
			Name:       "wg0",
			ConfigPath: "/etc/wireguard/wg0.conf",
			Content:    sb.String(),
		}}},
		WriteFiles: []writeFile{{
			Append:  true,
			Content: "net.ipv4.ip_forward=1",
			Path:    "/etc/sysctl.d/99-sysctl.conf",
		}},
	}, nil
}

type cloudConfig struct {
	PackageRebootIfRequired bool        `json:"package_reboot_if_required,omitempty"`
	PackageUpdate           bool        `json:"package_update,omitempty"`
	PackageUpgrade          bool        `json:"package_upgrade,omitempty"`
	Packages                []string    `json:"packages,omitempty"`
	RunCmd                  [][]string  `json:"runcmd,omitempty"`
	Snap                    snap        `json:"snap,omitempty"`
	Wireguard               wg          `json:"wireguard,omitempty"`
	WriteFiles              []writeFile `json:"write_files,omitempty"`
}

type snap struct {
	Commands [][]string `json:"commands"`
}

type wg struct {
	Interfaces []wgInterface `json:"interfaces"`
}

type wgInterface struct {
	ConfigPath string `json:"config_path"`
	Content    string `json:"content"`
	Name       string `json:"name"`
}

type writeFile struct {
	Append  bool   `json:"append"`
	Content string `json:"content"`
	Path    string `json:"path"`
}

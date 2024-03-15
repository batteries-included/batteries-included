package eks

import (
	"encoding/json"
	"fmt"
	"slices"
	"strconv"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/ec2"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/iam"
	pvpc "github.com/pulumi/pulumi-aws/sdk/v6/go/aws/vpc"
	"github.com/pulumi/pulumi-cloudinit/sdk/go/cloudinit"
	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

type gateway struct {
	// config
	baseName         string
	wireguardName    string
	vpcCidrBlock     string
	gatewayCidrBlock string
	generateKey      bool
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
	publicIP                                     pulumi.StringOutput
}

// TODO(jdt): reflexively get config values based on struct tags
func (g *gateway) withConfig(cfg auto.ConfigMap) error {
	volumeSize, err := strconv.Atoi(cfg["gateway:volumeSize"].Value)
	if err != nil {
		return err
	}
	port, err := strconv.Atoi(cfg["gateway:port"].Value)
	if err != nil {
		return err
	}

	g.baseName = cfg["cluster:name"].Value
	g.gatewayCidrBlock = cfg["gateway:cidrBlock"].Value
	g.generateKey = cfg["gateway:generateKey"].Value == "true"
	g.instanceType = cfg["gateway:instanceType"].Value
	g.port = port
	g.volumeSize = volumeSize
	g.volumeType = cfg["gateway:volumeType"].Value
	g.vpcCidrBlock = cfg["vpc:cidrBlock"].Value
	g.wireguardName = g.baseName + "-wireguard"

	return nil
}

func (g *gateway) withOutputs(outputs map[string]auto.OutputMap) error {
	g.vpcID = outputs["vpc"]["vpcID"].Value.(string)

	g.publicSubnetIDs = toStringSlice(outputs["vpc"]["publicSubnetIDs"].Value)
	g.privateSubnetIDs = toStringSlice(outputs["vpc"]["privateSubnetIDs"].Value)

	return nil
}

// NOTE(jdt): this kind of stinks. There doesn't appear to be a convenient way to convert the outputs from previous stacks into usable inputs.
// We just get an empty interface - `interface{}` - that we have to type assert. Perhaps we should use JSON?
func toStringSlice(in interface{}) []string {
	out := []string{}
	for _, x := range in.([]interface{}) {
		out = append(out, x.(string))
	}
	// try to maintain some order so that things don't flip flop?
	slices.Sort(out)
	return out
}

func (g *gateway) run(ctx *pulumi.Context) error {
	for _, fn := range []func(*pulumi.Context) error{
		g.securityGroup,
		g.keyPair,
		g.iamProfile,
		g.ec2Instance,
		g.eip,
	} {
		if err := fn(ctx); err != nil {
			return err
		}
	}

	ctx.Export("gatewayPublicIP", g.publicIP)
	ctx.Export("gatewaySecurityGroupID", g.securityGroupID)

	return nil
}

func (g *gateway) securityGroup(ctx *pulumi.Context) error {
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

	allCidr, wgCidr, vpcCidr := pulumi.String("0.0.0.0/0"), pulumi.String(g.gatewayCidrBlock), pulumi.String(g.vpcCidrBlock)

	rules := map[string]struct {
		port  pulumi.Int
		proto pulumi.String
		cidr  pulumi.String
	}{
		"ssh-all":  {port: pulumi.Int(22), proto: pulumi.String("tcp"), cidr: allCidr},
		"wg-all":   {port: pulumi.Int(g.port), proto: pulumi.String("udp"), cidr: allCidr},
		"dns-wg":   {port: pulumi.Int(53), proto: pulumi.String("udp"), cidr: wgCidr},
		"icmp-wg":  {port: pulumi.Int(-1), proto: pulumi.String("icmp"), cidr: wgCidr},
		"icmp-vpc": {port: pulumi.Int(-1), proto: pulumi.String("icmp"), cidr: vpcCidr},
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

func (g *gateway) keyPair(ctx *pulumi.Context) error { return nil }

func (g *gateway) iamProfile(ctx *pulumi.Context) error {

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
		ForceDetachPolicies: pulumi.BoolPtr(true),
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

func (g *gateway) ec2Instance(ctx *pulumi.Context) error {
	cc := g.buildCloudConfig()
	ccBytes, err := json.Marshal(&cc)
	if err != nil {
		return err
	}

	conf, err := cloudinit.NewConfig(ctx, g.wireguardName, &cloudinit.ConfigArgs{
		Gzip:         pulumi.Bool(false),
		Base64Encode: pulumi.Bool(false),

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

	instance, err := ec2.NewInstance(ctx, g.wireguardName, &ec2.InstanceArgs{
		// KeyName: ,
		Ami:                 pulumi.String(ami.Id),
		SubnetId:            pulumi.String(g.publicSubnetIDs[0]),
		InstanceType:        pulumi.String(g.instanceType),
		VpcSecurityGroupIds: pulumi.StringArray{g.securityGroupID},
		IamInstanceProfile:  g.iamProfileID,
		Tags:                pulumi.StringMap{"Name": pulumi.String(g.wireguardName)},
		UserData:            conf.Rendered,
		MetadataOptions: ec2.InstanceMetadataOptionsArgs{
			HttpTokens: pulumi.String("required"),
		},

		RootBlockDevice: ec2.InstanceRootBlockDeviceArgs{
			VolumeType: pulumi.String(g.volumeType),
			VolumeSize: pulumi.Int(g.volumeSize),
		},
		// UserDataReplaceOnChange: pulumi.BoolPtr(true),
	}, pulumi.ReplaceOnChanges([]string{"UserData"}), pulumi.IgnoreChanges([]string{"ami"}))
	if err != nil {
		return err
	}

	g.ec2InstanceID = instance.ID()

	return nil
}

func (g *gateway) eip(ctx *pulumi.Context) error {
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

func (g *gateway) buildCloudConfig() *cloudConfig {
	// TODO(jdt): don't hard code keys
	conf := `# AUTOGENERATED
[Interface]
PrivateKey = QLLDkkqoXTBkAohmdvQobEmYlcneMruUeqBO3LWem00=
Address = %s
ListenPort = %d
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT ; iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ens5 -j MASQUERADE

[Peer]
PublicKey = ntFtPw8qVf9U6Uc1RELWdtCUlK3FpREnwR+LGfFxrzM=
AllowedIPs = 0.0.0.0/0
[Peer]
PublicKey = iMQngW+5Wfx2kbAk9qdhiXB46rYUA5c2yDkJRfbHklg=
AllowedIPs = 0.0.0.0/0
    `

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
		Wireguard: wireguard{Interfaces: []wgInterface{{
			Name:       "wg0",
			ConfigPath: "/etc/wireguard/wg0.conf",
			Content:    fmt.Sprintf(conf, g.gatewayCidrBlock, g.port),
		}}},
		WriteFiles: []writeFile{{
			Append:  true,
			Content: "net.ipv4.ip_forward=1",
			Path:    "/etc/sysctl.d/99-sysctl.conf",
		}},
	}
}

func debug(v interface{}) { fmt.Printf("%+v\n", v) }

type cloudConfig struct {
	PackageRebootIfRequired bool        `json:"package_reboot_if_required"`
	PackageUpdate           bool        `json:"package_update"`
	PackageUpgrade          bool        `json:"package_upgrade"`
	Packages                []string    `json:"packages"`
	RunCmd                  [][]string  `json:"runcmd"`
	Snap                    snap        `json:"snap"`
	Wireguard               wireguard   `json:"wireguard"`
	WriteFiles              []writeFile `json:"write_files"`
}

type snap struct {
	Commands [][]string `json:"commands"`
}

type wireguard struct {
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

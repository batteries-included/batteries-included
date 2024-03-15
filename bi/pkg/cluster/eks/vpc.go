package eks

import (
	"fmt"
	"net"
	"slices"

	"github.com/apparentlymart/go-cidr/cidr"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/ec2"
	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

var subnetTypes = []string{"public", "private"}

type vpc struct {
	// set in new
	baseName  string
	cidrBlock string
	net       *net.IPNet

	// state accumulation
	azs         *aws.GetAvailabilityZonesResult
	azNames     []string
	azIDs       []string
	vpc         *ec2.Vpc
	vpcID       pulumi.IDOutput
	subnets     map[string][]*ec2.Subnet
	gateways    map[string]pulumi.IDOutput
	routeTables map[string]pulumi.IDOutput
}

func (v *vpc) withConfig(cfg auto.ConfigMap) error {
	v.baseName = cfg["cluster:name"].Value
	v.cidrBlock = cfg["vpc:cidrBlock"].Value

	_, net, err := net.ParseCIDR(v.cidrBlock)
	if err != nil {
		return err
	}
	v.net = net

	return nil
}

// VPC is the first component created. It cannot rely on previous components outputs.
func (v *vpc) withOutputs(outputs map[string]auto.OutputMap) error { return nil }

func (v *vpc) run(ctx *pulumi.Context) error {
	for _, fn := range []func(*pulumi.Context) error{
		v.getAZS,
		v.buildVPC,
		v.buildSubnets,
		v.buildGateways,
		v.buildRouteTables,
		v.buildRouteTableAssocs,
	} {
		if err := fn(ctx); err != nil {
			return err
		}
	}

	ctx.Export("vpcID", v.vpcID)
	ctx.Export("publicSubnetIDs", toIDArray(v.subnets["public"]))
	ctx.Export("privateSubnetIDs", toIDArray(v.subnets["private"]))

	return nil
}

func toIDArray(subnets []*ec2.Subnet) pulumi.IDArrayOutput {
	out := []pulumi.IDOutput{}
	for _, subnet := range subnets {
		out = append(out, subnet.ID())
	}
	return pulumi.ToIDArrayOutput(out)
}

func (v *vpc) getAZS(ctx *pulumi.Context) error {
	azs, err := aws.GetAvailabilityZones(ctx, &aws.GetAvailabilityZonesArgs{
		State:          pulumi.StringRef("available"),
		ExcludeZoneIds: []string{"use1-az3", "usw1-az2", "cac1-az3"},
		Filters: []aws.GetAvailabilityZonesFilter{{
			Name:   "zone-type",
			Values: []string{"availability-zone"},
		}},
	})

	if err != nil {

		return err
	}

	v.azs = azs

	azNames := v.azs.Names
	slices.Sort(azNames)
	v.azNames = azNames

	azIDs := v.azs.ZoneIds
	slices.Sort(azIDs)
	v.azIDs = azIDs
	return nil
}

func (v *vpc) buildVPC(ctx *pulumi.Context) error {
	vpc, err := ec2.NewVpc(ctx, v.baseName, &ec2.VpcArgs{
		CidrBlock:          pulumi.StringPtr(v.cidrBlock),
		Tags:               pulumi.StringMap{"Name": pulumi.String(v.baseName)},
		EnableDnsHostnames: pulumi.BoolPtr(true),
	})
	if err != nil {
		return err
	}
	v.vpc = vpc
	v.vpcID = vpc.ID()
	return nil
}

func (v *vpc) buildSubnets(ctx *pulumi.Context) error {

	subnets := make(map[string][]*ec2.Subnet)
	for i, az := range v.azNames {
		for j, p := range subnetTypes {
			netNum := i + (100 * j) + 1 // 1 through x for public 101 through x for private
			net, err := cidr.Subnet(v.net, 8, netNum)
			if err != nil {
				return err
			}

			name := fmt.Sprintf("%s-%s-%s", v.baseName, p, az)

			subnet, err := ec2.NewSubnet(ctx, name, &ec2.SubnetArgs{
				VpcId:     v.vpcID,
				CidrBlock: pulumi.String(net.String()),
				Tags:      pulumi.StringMap{"Name": pulumi.String(name)},
			}, pulumi.Parent(v.vpc))
			if err != nil {
				return err
			}

			subnets[p] = append(subnets[p], subnet)
		}
	}
	v.subnets = subnets
	return nil
}

func (v *vpc) buildGateways(ctx *pulumi.Context) error {
	parent := pulumi.Parent(v.vpc)
	// igw
	name := v.baseName + "-internet-gateway"
	igw, err := ec2.NewInternetGateway(ctx, name, &ec2.InternetGatewayArgs{
		VpcId: v.vpcID,
		Tags:  pulumi.StringMap{"Name": pulumi.String(name)},
	}, parent)
	if err != nil {
		return err
	}

	igwDependency := pulumi.DependsOn([]pulumi.Resource{igw})

	// nat gw
	name = v.baseName + "-nat-gateway"
	eip, err := ec2.NewEip(ctx, name, &ec2.EipArgs{
		Domain: pulumi.String("vpc"),
		Tags:   pulumi.StringMap{"Name": pulumi.String(name)},
	}, igwDependency, parent)
	if err != nil {
		return err
	}

	ngw, err := ec2.NewNatGateway(ctx, name, &ec2.NatGatewayArgs{
		AllocationId: eip.ID(),
		SubnetId:     v.subnets["public"][0].ID(),
		Tags:         pulumi.StringMap{"Name": pulumi.String(name)},
	}, igwDependency, parent)
	if err != nil {
		return err
	}

	v.gateways = map[string]pulumi.IDOutput{
		"public":  igw.ID(),
		"private": ngw.ID(),
	}
	return nil
}

func (v *vpc) buildRouteTables(ctx *pulumi.Context) error {
	// rename default route table
	name := v.baseName + "-default"
	dflt, err := ec2.NewDefaultRouteTable(ctx, name, &ec2.DefaultRouteTableArgs{
		DefaultRouteTableId: v.vpc.DefaultRouteTableId,
		Tags:                pulumi.StringMap{"Name": pulumi.String(name)},
	})
	if err != nil {
		return err
	}

	v.routeTables = map[string]pulumi.IDOutput{"default": dflt.ID()}
	for _, t := range subnetTypes {
		rtName := fmt.Sprintf("%s-%s", v.baseName, t)

		var internetRoute *ec2.RouteTableRouteArgs
		switch t {
		case "public":
			internetRoute = &ec2.RouteTableRouteArgs{
				CidrBlock: pulumi.String("0.0.0.0/0"),
				GatewayId: v.gateways[t],
			}
		case "private":
			internetRoute = &ec2.RouteTableRouteArgs{
				CidrBlock:    pulumi.String("0.0.0.0/0"),
				NatGatewayId: v.gateways[t],
			}

		}

		rt, err := ec2.NewRouteTable(ctx, rtName, &ec2.RouteTableArgs{
			VpcId: v.vpcID,
			Routes: ec2.RouteTableRouteArray{
				&ec2.RouteTableRouteArgs{
					CidrBlock: pulumi.StringPtr(v.cidrBlock),
					GatewayId: pulumi.String("local"),
				},
				internetRoute,
			},
			Tags: pulumi.StringMap{
				"Name": pulumi.String(rtName),
			},
		})
		if err != nil {
			return err
		}
		v.routeTables[t] = rt.ID()
	}
	return nil
}

func (v *vpc) buildRouteTableAssocs(ctx *pulumi.Context) error {
	for _, t := range subnetTypes {
		for i, subnet := range v.subnets[t] {
			name := fmt.Sprintf("%s-%s-%d-rta", v.baseName, t, i)

			_, err := ec2.NewRouteTableAssociation(ctx, name, &ec2.RouteTableAssociationArgs{
				SubnetId:     subnet.ID(),
				RouteTableId: v.routeTables[t],
			})
			if err != nil {
				return err
			}
		}
	}
	return nil
}

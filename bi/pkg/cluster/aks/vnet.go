package aks

import (
	"bi/pkg/cluster/util"
	"fmt"

	"github.com/pulumi/pulumi-azure-native-sdk/network/v2"
	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

type vnetConfig struct {
	resourceGroupName pulumi.StringPtrInput
	location          pulumi.StringPtrInput
	vnetName          pulumi.StringPtrInput
	addressSpace      pulumi.StringPtrInput
	subnetName        pulumi.StringPtrInput
	subnetPrefix      pulumi.StringPtrInput
	gatewaySubnetName pulumi.StringPtrInput
	gatewaySubnetPrefix pulumi.StringPtrInput
	tags              pulumi.StringMapInput
}

func (v *vnetConfig) withConfig(pConfig *util.PulumiConfig) error {
	v.resourceGroupName = pConfig.RequireString("azure:resourceGroupName")
	v.location = pConfig.RequireString("azure:location")
	v.vnetName = pConfig.RequireString("azure:vnetName")
	v.addressSpace = pConfig.GetString("azure:addressSpace", "10.0.0.0/16")
	v.subnetName = pConfig.GetString("azure:subnetName", "aks-subnet")
	v.subnetPrefix = pConfig.GetString("azure:subnetPrefix", "10.0.1.0/24")
	v.gatewaySubnetName = pConfig.GetString("azure:gatewaySubnetName", "gateway-subnet")
	v.gatewaySubnetPrefix = pConfig.GetString("azure:gatewaySubnetPrefix", "10.0.2.0/24")

	// Set up tags
	tags := map[string]string{
		"Environment": "batteries-included",
		"ManagedBy":   "pulumi",
	}
	
	if project := pConfig.GetString("azure:project", ""); project != "" {
		tags["Project"] = project
	}
	
	v.tags = pulumi.ToStringMap(tags)

	return nil
}

func (v *vnetConfig) withOutputs(outputs map[string]auto.OutputMap) error {
	if rg, ok := outputs["resourcegroup"]; ok {
		if name, ok := rg["name"]; ok {
			v.resourceGroupName = pulumi.String(name.Value.(string))
		}
	}
	return nil
}

func (v *vnetConfig) run(ctx *pulumi.Context) error {
	// Create virtual network
	vnet, err := network.NewVirtualNetwork(ctx, "vnet", &network.VirtualNetworkArgs{
		ResourceGroupName:    v.resourceGroupName,
		VirtualNetworkName:   v.vnetName,
		Location:             v.location,
		AddressSpace: &network.AddressSpaceArgs{
			AddressPrefixes: pulumi.StringArray{
				v.addressSpace,
			},
		},
		Tags: v.tags,
	})
	if err != nil {
		return fmt.Errorf("failed to create virtual network: %w", err)
	}

	// Create AKS subnet
	aksSubnet, err := network.NewSubnet(ctx, "aks-subnet", &network.SubnetArgs{
		ResourceGroupName:  v.resourceGroupName,
		VirtualNetworkName: vnet.Name,
		SubnetName:         v.subnetName,
		AddressPrefix:      v.subnetPrefix,
	})
	if err != nil {
		return fmt.Errorf("failed to create AKS subnet: %w", err)
	}

	// Create gateway subnet
	gatewaySubnet, err := network.NewSubnet(ctx, "gateway-subnet", &network.SubnetArgs{
		ResourceGroupName:  v.resourceGroupName,
		VirtualNetworkName: vnet.Name,
		SubnetName:         v.gatewaySubnetName,
		AddressPrefix:      v.gatewaySubnetPrefix,
	})
	if err != nil {
		return fmt.Errorf("failed to create gateway subnet: %w", err)
	}

	// Export VNet information
	ctx.Export("name", vnet.Name)
	ctx.Export("id", vnet.ID())
	ctx.Export("resourceGroupName", vnet.ResourceGroupName)
	ctx.Export("location", vnet.Location)
	ctx.Export("addressSpace", v.addressSpace)
	ctx.Export("subnetName", aksSubnet.Name)
	ctx.Export("subnetId", aksSubnet.ID())
	ctx.Export("subnetPrefix", v.subnetPrefix)
	ctx.Export("gatewaySubnetName", gatewaySubnet.Name)
	ctx.Export("gatewaySubnetId", gatewaySubnet.ID())
	ctx.Export("gatewaySubnetPrefix", v.gatewaySubnetPrefix)

	return nil
}
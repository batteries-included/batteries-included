package aks

import (
	"bi/pkg/cluster/util"
	"fmt"

	"github.com/pulumi/pulumi-azure-native-sdk/compute/v2"
	"github.com/pulumi/pulumi-azure-native-sdk/network/v2"
	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

type gatewayConfig struct {
	resourceGroupName   pulumi.StringPtrInput
	location            pulumi.StringPtrInput
	gatewaySubnetId     pulumi.StringPtrInput
	gatewayVmSize       pulumi.StringPtrInput
	wgGatewayPrivateKey pulumi.StringPtrInput
	wgGatewayAddress    pulumi.StringPtrInput
	wgClientPrivateKey  pulumi.StringPtrInput
	wgClientAddress     pulumi.StringPtrInput
	tags                pulumi.StringMapInput
}

func (g *gatewayConfig) withConfig(pConfig *util.PulumiConfig) error {
	g.resourceGroupName = pConfig.RequireString("azure:resourceGroupName")
	g.location = pConfig.RequireString("azure:location")
	g.gatewayVmSize = pConfig.GetString("azure:gatewayVmSize", "Standard_B1s")
	g.wgGatewayPrivateKey = pConfig.GetString("azure:wgGatewayPrivateKey", "")
	g.wgGatewayAddress = pConfig.GetString("azure:wgGatewayAddress", "10.99.0.1")
	g.wgClientPrivateKey = pConfig.GetString("azure:wgClientPrivateKey", "")
	g.wgClientAddress = pConfig.GetString("azure:wgClientAddress", "10.99.0.2")

	// Set up tags
	tags := map[string]string{
		"Environment": "batteries-included",
		"ManagedBy":   "pulumi",
		"Component":   "gateway",
	}
	
	if project := pConfig.GetString("azure:project", ""); project != "" {
		tags["Project"] = project
	}
	
	g.tags = pulumi.ToStringMap(tags)

	return nil
}

func (g *gatewayConfig) withOutputs(outputs map[string]auto.OutputMap) error {
	if rg, ok := outputs["resourcegroup"]; ok {
		if name, ok := rg["name"]; ok {
			g.resourceGroupName = pulumi.String(name.Value.(string))
		}
	}

	if vnet, ok := outputs["vnet"]; ok {
		if subnetId, ok := vnet["gatewaySubnetId"]; ok {
			g.gatewaySubnetId = pulumi.String(subnetId.Value.(string))
		}
	}

	return nil
}

func (g *gatewayConfig) run(ctx *pulumi.Context) error {
	// Create public IP for gateway
	publicIP, err := network.NewPublicIPAddress(ctx, "gateway-public-ip", &network.PublicIPAddressArgs{
		ResourceGroupName:    g.resourceGroupName,
		PublicIpAddressName:  pulumi.String("gateway-public-ip"),
		Location:             g.location,
		PublicIPAllocationMethod: network.IPAllocationMethodStatic,
		Sku: &network.PublicIPAddressSkuArgs{
			Name: network.PublicIPAddressSkuNameStandard,
		},
		Tags: g.tags,
	})
	if err != nil {
		return fmt.Errorf("failed to create public IP: %w", err)
	}

	// Create network security group for gateway
	nsg, err := network.NewNetworkSecurityGroup(ctx, "gateway-nsg", &network.NetworkSecurityGroupArgs{
		ResourceGroupName:        g.resourceGroupName,
		NetworkSecurityGroupName: pulumi.String("gateway-nsg"),
		Location:                 g.location,
		SecurityRules: network.SecurityRuleArray{
			&network.SecurityRuleArgs{
				Name:                     pulumi.String("allow-wireguard"),
				Priority:                 pulumi.Int(100),
				Direction:                network.SecurityRuleDirectionInbound,
				Access:                   network.SecurityRuleAccessAllow,
				Protocol:                 network.SecurityRuleProtocolUdp,
				SourcePortRange:          pulumi.String("*"),
				DestinationPortRange:     pulumi.String("51820"),
				SourceAddressPrefix:      pulumi.String("*"),
				DestinationAddressPrefix: pulumi.String("*"),
			},
			&network.SecurityRuleArgs{
				Name:                     pulumi.String("allow-ssh"),
				Priority:                 pulumi.Int(200),
				Direction:                network.SecurityRuleDirectionInbound,
				Access:                   network.SecurityRuleAccessAllow,
				Protocol:                 network.SecurityRuleProtocolTcp,
				SourcePortRange:          pulumi.String("*"),
				DestinationPortRange:     pulumi.String("22"),
				SourceAddressPrefix:      pulumi.String("*"),
				DestinationAddressPrefix: pulumi.String("*"),
			},
		},
		Tags: g.tags,
	})
	if err != nil {
		return fmt.Errorf("failed to create network security group: %w", err)
	}

	// Create network interface for gateway
	nic, err := network.NewNetworkInterface(ctx, "gateway-nic", &network.NetworkInterfaceArgs{
		ResourceGroupName:    g.resourceGroupName,
		NetworkInterfaceName: pulumi.String("gateway-nic"),
		Location:             g.location,
		IpConfigurations: network.NetworkInterfaceIPConfigurationArray{
			&network.NetworkInterfaceIPConfigurationArgs{
				Name:                          pulumi.String("ipconfig1"),
				PrivateIPAllocationMethod:     network.IPAllocationMethodDynamic,
				PublicIPAddress: &network.PublicIPAddressTypeArgs{
					Id: publicIP.ID(),
				},
				Subnet: &network.SubnetTypeArgs{
					Id: g.gatewaySubnetId,
				},
			},
		},
		NetworkSecurityGroup: &network.NetworkSecurityGroupTypeArgs{
			Id: nsg.ID(),
		},
		Tags: g.tags,
	})
	if err != nil {
		return fmt.Errorf("failed to create network interface: %w", err)
	}

	// Create gateway VM
	vm, err := compute.NewVirtualMachine(ctx, "gateway-vm", &compute.VirtualMachineArgs{
		ResourceGroupName: g.resourceGroupName,
		VmName:            pulumi.String("gateway-vm"),
		Location:          g.location,
		VmSize:            g.gatewayVmSize,
		NetworkProfile: &compute.NetworkProfileArgs{
			NetworkInterfaces: compute.NetworkInterfaceReferenceArray{
				&compute.NetworkInterfaceReferenceArgs{
					Id: nic.ID(),
				},
			},
		},
		OsProfile: &compute.OSProfileArgs{
			ComputerName:  pulumi.String("gateway"),
			AdminUsername: pulumi.String("azureuser"),
			LinuxConfiguration: &compute.LinuxConfigurationArgs{
				DisablePasswordAuthentication: pulumi.Bool(true),
				Ssh: &compute.SshConfigurationArgs{
					PublicKeys: compute.SshPublicKeyArray{
						&compute.SshPublicKeyArgs{
							Path:    pulumi.String("/home/azureuser/.ssh/authorized_keys"),
							KeyData: pulumi.String("ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTgvwjlRHZ..."), // Placeholder
						},
					},
				},
			},
		},
		StorageProfile: &compute.StorageProfileArgs{
			ImageReference: &compute.ImageReferenceArgs{
				Publisher: pulumi.String("Canonical"),
				Offer:     pulumi.String("0001-com-ubuntu-server-focal"),
				Sku:       pulumi.String("20_04-lts-gen2"),
				Version:   pulumi.String("latest"),
			},
			OsDisk: &compute.OSDiskArgs{
				CreateOption: compute.DiskCreateOptionTypesFromImage,
				ManagedDisk: &compute.ManagedDiskParametersArgs{
					StorageAccountType: compute.StorageAccountTypesStandardLRS,
				},
			},
		},
		Tags: g.tags,
	})
	if err != nil {
		return fmt.Errorf("failed to create virtual machine: %w", err)
	}

	// Export gateway information
	ctx.Export("vmId", vm.ID())
	ctx.Export("vmName", vm.Name)
	ctx.Export("publicIP", publicIP.IpAddress)
	ctx.Export("publicPort", pulumi.Int(51820))
	ctx.Export("wgGatewayPrivateKey", g.wgGatewayPrivateKey)
	ctx.Export("wgGatewayAddress", g.wgGatewayAddress)
	ctx.Export("wgClientPrivateKey", g.wgClientPrivateKey)
	ctx.Export("wgClientAddress", g.wgClientAddress)

	return nil
}
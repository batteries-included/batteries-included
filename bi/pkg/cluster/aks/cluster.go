package aks

import (
	"bi/pkg/cluster/util"
	"fmt"

	"github.com/pulumi/pulumi-azure-native-sdk/authorization/v2"
	"github.com/pulumi/pulumi-azure-native-sdk/containerservice/v2"
	"github.com/pulumi/pulumi-azure-native-sdk/network/v2"
	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

type clusterConfig struct {
	resourceGroupName pulumi.StringPtrInput
	vnetName          pulumi.StringPtrInput
	subnetName        pulumi.StringPtrInput
	location          pulumi.StringPtrInput
	clusterName       pulumi.StringPtrInput
	nodePoolName      pulumi.StringPtrInput
	kubernetesVersion pulumi.StringPtrInput
	nodeCount         pulumi.IntPtrInput
	vmSize            pulumi.StringPtrInput
	diskSizeGB        pulumi.IntPtrInput
	enableAutoScaling pulumi.BoolPtrInput
	minCount          pulumi.IntPtrInput
	maxCount          pulumi.IntPtrInput
}

func (c *clusterConfig) withConfig(pConfig *util.PulumiConfig) error {
	c.resourceGroupName = pConfig.RequireString("azure:resourceGroupName")
	c.vnetName = pConfig.RequireString("azure:vnetName")
	c.subnetName = pConfig.RequireString("azure:subnetName")
	c.location = pConfig.RequireString("azure:location")
	c.clusterName = pConfig.RequireString("azure:clusterName")
	c.nodePoolName = pConfig.GetString("azure:nodePoolName", "default")
	c.kubernetesVersion = pConfig.GetString("azure:kubernetesVersion", "1.28.0")
	c.nodeCount = pConfig.GetInt("azure:nodeCount", 3)
	c.vmSize = pConfig.GetString("azure:vmSize", "Standard_D2s_v3")
	c.diskSizeGB = pConfig.GetInt("azure:diskSizeGB", 30)
	c.enableAutoScaling = pConfig.GetBool("azure:enableAutoScaling", true)
	c.minCount = pConfig.GetInt("azure:minCount", 1)
	c.maxCount = pConfig.GetInt("azure:maxCount", 10)

	return nil
}

func (c *clusterConfig) withOutputs(outputs map[string]auto.OutputMap) error {
	if rg, ok := outputs["resourcegroup"]; ok {
		if name, ok := rg["name"]; ok {
			c.resourceGroupName = pulumi.String(name.Value.(string))
		}
	}

	if vnet, ok := outputs["vnet"]; ok {
		if name, ok := vnet["name"]; ok {
			c.vnetName = pulumi.String(name.Value.(string))
		}
		if subnetName, ok := vnet["subnetName"]; ok {
			c.subnetName = pulumi.String(subnetName.Value.(string))
		}
	}

	return nil
}

func (c *clusterConfig) run(ctx *pulumi.Context) error {
	// Get the subnet resource
	subnet, err := network.LookupSubnet(ctx, &network.LookupSubnetArgs{
		ResourceGroupName:  c.resourceGroupName.(pulumi.StringInput).ToStringPtrOutput().Elem().ToStringOutput(),
		VirtualNetworkName: c.vnetName.(pulumi.StringInput).ToStringPtrOutput().Elem().ToStringOutput(),
		SubnetName:         c.subnetName.(pulumi.StringInput).ToStringPtrOutput().Elem().ToStringOutput(),
	})
	if err != nil {
		return fmt.Errorf("failed to get subnet: %w", err)
	}

	// Create AKS cluster
	cluster, err := containerservice.NewManagedCluster(ctx, "aks-cluster", &containerservice.ManagedClusterArgs{
		ResourceGroupName: c.resourceGroupName,
		ResourceName:      c.clusterName,
		Location:          c.location,
		KubernetesVersion: c.kubernetesVersion,
		DnsPrefix:         pulumi.Sprintf("%s-dns", c.clusterName),
		
		// Enable managed identity
		Identity: &containerservice.ManagedClusterIdentityArgs{
			Type: containerservice.ResourceIdentityTypeSystemAssigned,
		},

		// Network configuration
		NetworkProfile: &containerservice.ContainerServiceNetworkProfileArgs{
			NetworkPlugin: pulumi.String("azure"),
			ServiceCidr:   pulumi.String("10.100.0.0/16"),
			DnsServiceIp:  pulumi.String("10.100.0.10"),
		},

		// Agent pool configuration
		AgentPoolProfiles: containerservice.ManagedClusterAgentPoolProfileArray{
			&containerservice.ManagedClusterAgentPoolProfileArgs{
				Name:              c.nodePoolName,
				Count:             c.nodeCount,
				VmSize:            c.vmSize,
				OsDiskSizeGb:      c.diskSizeGB,
				OsType:            pulumi.String("Linux"),
				Mode:              pulumi.String("System"),
				EnableAutoScaling: c.enableAutoScaling,
				MinCount:          c.minCount,
				MaxCount:          c.maxCount,
				VnetSubnetId:      pulumi.String(subnet.Id),
			},
		},

		// Enable workload identity and OIDC issuer
		OidcIssuerProfile: &containerservice.ManagedClusterOidcIssuerProfileArgs{
			Enabled: pulumi.Bool(true),
		},
		SecurityProfile: &containerservice.ManagedClusterSecurityProfileArgs{
			WorkloadIdentity: &containerservice.ManagedClusterSecurityProfileWorkloadIdentityArgs{
				Enabled: pulumi.Bool(true),
			},
		},

		// Enable addon profiles
		AddonProfiles: containerservice.ManagedClusterAddonProfileMap{
			"httpApplicationRouting": &containerservice.ManagedClusterAddonProfileArgs{
				Enabled: pulumi.Bool(false),
			},
			"azureKeyvaultSecretsProvider": &containerservice.ManagedClusterAddonProfileArgs{
				Enabled: pulumi.Bool(true),
			},
			"acrpull": &containerservice.ManagedClusterAddonProfileArgs{
				Enabled: pulumi.Bool(true),
			},
		},

		// Enable API server access
		ApiServerAccessProfile: &containerservice.ManagedClusterApiServerAccessProfileArgs{
			EnablePrivateCluster: pulumi.Bool(false),
		},
	})
	if err != nil {
		return fmt.Errorf("failed to create AKS cluster: %w", err)
	}

	// Create role assignment for the cluster managed identity to access the subnet
	_, err = authorization.NewRoleAssignment(ctx, "cluster-network-contributor", &authorization.RoleAssignmentArgs{
		Scope:            pulumi.String(subnet.Id),
		RoleDefinitionId: pulumi.String("/subscriptions/" + ctx.Stack() + "/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7"), // Network Contributor
		PrincipalId:      cluster.Identity.PrincipalId().Elem(),
		PrincipalType:    pulumi.String("ServicePrincipal"),
	})
	if err != nil {
		return fmt.Errorf("failed to create role assignment: %w", err)
	}

	// Export cluster information
	ctx.Export("name", cluster.Name)
	ctx.Export("resourceGroupName", cluster.ResourceGroupName)
	ctx.Export("location", cluster.Location)
	ctx.Export("kubernetesVersion", cluster.KubernetesVersion)
	ctx.Export("fqdn", cluster.Fqdn)
	ctx.Export("nodeResourceGroup", cluster.NodeResourceGroup)
	ctx.Export("oidcIssuerUrl", cluster.OidcIssuerProfile.IssuerUrl())
	ctx.Export("principalId", cluster.Identity.PrincipalId())
	ctx.Export("identityType", cluster.Identity.Type())

	// Export kubeconfig
	ctx.Export("kubeconfig", pulumi.ToSecret(cluster.KubeConfig))

	return nil
}
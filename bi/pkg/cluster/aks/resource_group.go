package aks

import (
	"bi/pkg/cluster/util"
	"fmt"

	"github.com/pulumi/pulumi-azure-native-sdk/resources/v2"
	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

type resourceGroupConfig struct{
	resourceGroupName pulumi.StringPtrInput
	location          pulumi.StringPtrInput
	tags              pulumi.StringMapInput
}

func (rg *resourceGroupConfig) withConfig(pConfig *util.PulumiConfig) error {
	rg.resourceGroupName = pConfig.RequireString("azure:resourceGroupName")
	rg.location = pConfig.RequireString("azure:location")
	
	// Set up tags
	tags := map[string]string{
		"Environment": "batteries-included",
		"ManagedBy":   "pulumi",
	}
	
	if project := pConfig.GetString("azure:project", ""); project != "" {
		tags["Project"] = project
	}
	
	rg.tags = pulumi.ToStringMap(tags)
	
	return nil
}

func (rg *resourceGroupConfig) withOutputs(outputs map[string]auto.OutputMap) error {
	// No dependencies on other components
	return nil
}

func (rg *resourceGroupConfig) run(ctx *pulumi.Context) error {
	// Create resource group
	resourceGroup, err := resources.NewResourceGroup(ctx, "resource-group", &resources.ResourceGroupArgs{
		ResourceGroupName: rg.resourceGroupName,
		Location:          rg.location,
		Tags:              rg.tags,
	})
	if err != nil {
		return fmt.Errorf("failed to create resource group: %w", err)
	}

	// Export resource group information
	ctx.Export("name", resourceGroup.Name)
	ctx.Export("location", resourceGroup.Location)
	ctx.Export("id", resourceGroup.ID())
	ctx.Export("tags", resourceGroup.Tags)

	return nil
}

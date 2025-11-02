package aks

import (
	"bi/pkg/cluster/util"

	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

type cnpgConfig struct {
	clusterName        pulumi.StringPtrInput
	resourceGroupName  pulumi.StringPtrInput
	storageAccountName pulumi.StringPtrInput
	enabled            pulumi.BoolPtrInput
}

func (c *cnpgConfig) withConfig(pConfig *util.PulumiConfig) error {
	c.clusterName = pConfig.RequireString("azure:clusterName")
	c.resourceGroupName = pConfig.RequireString("azure:resourceGroupName")
	c.storageAccountName = pConfig.GetString("azure:storageAccountName", "")
	c.enabled = pConfig.GetBool("azure:cnpgEnabled", true)

	return nil
}

func (c *cnpgConfig) withOutputs(outputs map[string]auto.OutputMap) error {
	if rg, ok := outputs["resourcegroup"]; ok {
		if name, ok := rg["name"]; ok {
			c.resourceGroupName = pulumi.String(name.Value.(string))
		}
	}

	if cluster, ok := outputs["cluster"]; ok {
		if name, ok := cluster["name"]; ok {
			c.clusterName = pulumi.String(name.Value.(string))
		}
	}

	return nil
}

func (c *cnpgConfig) run(ctx *pulumi.Context) error {
	// CloudNativePG for Azure - handles PostgreSQL deployment and backup to Azure Blob Storage
	// This component sets up the necessary configuration for CNPG on Azure
	
	// Export CNPG configuration
	ctx.Export("enabled", c.enabled)
	ctx.Export("clusterName", c.clusterName)
	ctx.Export("resourceGroupName", c.resourceGroupName)
	ctx.Export("storageAccountName", c.storageAccountName)

	return nil
}
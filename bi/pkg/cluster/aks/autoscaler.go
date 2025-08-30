package aks

import (
	"bi/pkg/cluster/util"

	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

type autoscalerConfig struct {
	clusterName           pulumi.StringPtrInput
	resourceGroupName     pulumi.StringPtrInput
	enabled               pulumi.BoolPtrInput
	scaleDownDelayAfterAdd pulumi.StringPtrInput
	scaleDownDelayAfterDelete pulumi.StringPtrInput
	scaleDownDelayAfterFailure pulumi.StringPtrInput
	scaleDownUnneededTime pulumi.StringPtrInput
	maxNodeProvisionTime  pulumi.StringPtrInput
}

func (as *autoscalerConfig) withConfig(pConfig *util.PulumiConfig) error {
	as.clusterName = pConfig.RequireString("azure:clusterName")
	as.resourceGroupName = pConfig.RequireString("azure:resourceGroupName")
	as.enabled = pConfig.GetBool("azure:autoscalerEnabled", true)
	as.scaleDownDelayAfterAdd = pConfig.GetString("azure:scaleDownDelayAfterAdd", "10m")
	as.scaleDownDelayAfterDelete = pConfig.GetString("azure:scaleDownDelayAfterDelete", "10s")
	as.scaleDownDelayAfterFailure = pConfig.GetString("azure:scaleDownDelayAfterFailure", "3m")
	as.scaleDownUnneededTime = pConfig.GetString("azure:scaleDownUnneededTime", "10m")
	as.maxNodeProvisionTime = pConfig.GetString("azure:maxNodeProvisionTime", "15m")

	return nil
}

func (as *autoscalerConfig) withOutputs(outputs map[string]auto.OutputMap) error {
	if rg, ok := outputs["resourcegroup"]; ok {
		if name, ok := rg["name"]; ok {
			as.resourceGroupName = pulumi.String(name.Value.(string))
		}
	}

	if cluster, ok := outputs["cluster"]; ok {
		if name, ok := cluster["name"]; ok {
			as.clusterName = pulumi.String(name.Value.(string))
		}
	}

	return nil
}

func (as *autoscalerConfig) run(ctx *pulumi.Context) error {
	// The Azure Cluster Autoscaler is deployed as a Kubernetes workload
	// This component handles any Azure-specific configuration needed for the autoscaler
	
	// Export autoscaler configuration
	ctx.Export("enabled", as.enabled)
	ctx.Export("clusterName", as.clusterName)
	ctx.Export("resourceGroupName", as.resourceGroupName)
	ctx.Export("scaleDownDelayAfterAdd", as.scaleDownDelayAfterAdd)
	ctx.Export("scaleDownDelayAfterDelete", as.scaleDownDelayAfterDelete)
	ctx.Export("scaleDownDelayAfterFailure", as.scaleDownDelayAfterFailure)
	ctx.Export("scaleDownUnneededTime", as.scaleDownUnneededTime)
	ctx.Export("maxNodeProvisionTime", as.maxNodeProvisionTime)

	return nil
}
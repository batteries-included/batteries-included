package aks

import (
	"bi/pkg/cluster/util"

	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

type loadBalancerConfig struct {
	clusterName       pulumi.StringPtrInput
	resourceGroupName pulumi.StringPtrInput
	enabled           pulumi.BoolPtrInput
}

func (lb *loadBalancerConfig) withConfig(pConfig *util.PulumiConfig) error {
	lb.clusterName = pConfig.RequireString("azure:clusterName")
	lb.resourceGroupName = pConfig.RequireString("azure:resourceGroupName")
	lb.enabled = pConfig.GetBool("azure:loadBalancerEnabled", true)

	return nil
}

func (lb *loadBalancerConfig) withOutputs(outputs map[string]auto.OutputMap) error {
	if rg, ok := outputs["resourcegroup"]; ok {
		if name, ok := rg["name"]; ok {
			lb.resourceGroupName = pulumi.String(name.Value.(string))
		}
	}

	if cluster, ok := outputs["cluster"]; ok {
		if name, ok := cluster["name"]; ok {
			lb.clusterName = pulumi.String(name.Value.(string))
		}
	}

	return nil
}

func (lb *loadBalancerConfig) run(ctx *pulumi.Context) error {
	// The Azure Load Balancer Controller is deployed as a Kubernetes workload
	// This component handles any Azure-specific configuration needed for the load balancer
	
	// Export load balancer configuration
	ctx.Export("enabled", lb.enabled)
	ctx.Export("clusterName", lb.clusterName)
	ctx.Export("resourceGroupName", lb.resourceGroupName)

	return nil
}
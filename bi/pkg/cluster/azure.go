package cluster

import (
	"context"
	"fmt"
	"io"
	"path"

	"bi/pkg/cluster/aks"
	"bi/pkg/cluster/util"
	"bi/pkg/specs"

	"github.com/adrg/xdg"
	"github.com/pulumi/pulumi/sdk/v3/go/auto"
)

const (
	azureHomeDir = "home"
	azureWorkDir = "work"
)

type azureProvider struct {
	initSuccessful bool
	spec           *specs.InstallSpec

	cfg auto.ConfigMap
	projectName,
	workDirRoot string

	pulumiHome auto.LocalWorkspaceOption
	pulumi     auto.LocalWorkspaceOption
	envVars    auto.LocalWorkspaceOption
}

func NewAzureProvider(spec *specs.InstallSpec) Provider {
	return &azureProvider{
		projectName: "bi-azure",
		spec:        spec,
	}
}

func (p *azureProvider) Init(ctx context.Context) error {
	_, err := p.configure(ctx)
	if err != nil {
		return fmt.Errorf("failed to configure azure provider: %w", err)
	}

	p.initSuccessful = true

	return nil
}

// configure sets up configuration common to all substacks
func (p *azureProvider) configure(ctx context.Context) (auto.Workspace, error) {
	stackName := auto.FullyQualifiedStackName("organization", p.projectName, p.spec.Slug)

	tags, err := newTags(stackName)
	if err != nil {
		return nil, fmt.Errorf("failed to create tags for %s: %w", stackName, err)
	}

	baseNS, err := p.spec.GetBatteryConfigField("battery_core", "base_namespace")
	if err != nil {
		return nil, fmt.Errorf("failed to get base namespace: %w", err)
	}

	// Set up Azure-specific configuration
	p.cfg = auto.ConfigMap{
		"azure:location":          auto.ConfigValue{Value: p.getAzureLocation()},
		"azure:subscriptionId":    auto.ConfigValue{Value: p.getAzureSubscriptionId()},
		"azure:tenantId":          auto.ConfigValue{Value: p.getAzureTenantId()},
		"azure:resourceGroupName": auto.ConfigValue{Value: fmt.Sprintf("%s-rg", p.spec.Slug)},
		"azure:clusterName":       auto.ConfigValue{Value: p.spec.Slug},
		"azure:vnetName":          auto.ConfigValue{Value: fmt.Sprintf("%s-vnet", p.spec.Slug)},
		"azure:subnetName":        auto.ConfigValue{Value: fmt.Sprintf("%s-subnet", p.spec.Slug)},
		"azure:gatewaySubnetName": auto.ConfigValue{Value: "GatewaySubnet"},
		"azure:kubernetesVersion": auto.ConfigValue{Value: "1.28.0"},
		"azure:nodeCount":         auto.ConfigValue{Value: "3"},
		"azure:vmSize":            auto.ConfigValue{Value: "Standard_D2s_v3"},
		"azure:diskSizeGB":        auto.ConfigValue{Value: "30"},
		"azure:enableAutoScaling": auto.ConfigValue{Value: "true"},
		"azure:minCount":          auto.ConfigValue{Value: "1"},
		"azure:maxCount":          auto.ConfigValue{Value: "10"},
		"azure:nodePoolName":      auto.ConfigValue{Value: "default"},
		"pulumi:tags":             auto.ConfigValue{Value: tags, Object: true},
		"batteries:baseNamespace": auto.ConfigValue{Value: baseNS},
	}

	// Set up workspace directories
	homeDir, err := xdg.DataFile(path.Join("bi", azureHomeDir))
	if err != nil {
		return nil, fmt.Errorf("failed to get home dir: %w", err)
	}

	p.workDirRoot, err = xdg.DataFile(path.Join("bi", azureWorkDir, p.spec.Slug))
	if err != nil {
		return nil, fmt.Errorf("failed to get work dir: %w", err)
	}

	p.pulumiHome = auto.PulumiHome(homeDir)
	p.pulumi = auto.EnvVars(map[string]string{
		"PULUMI_CONFIG_PASSPHRASE": "",
	})
	p.envVars = auto.EnvVars(map[string]string{
		"PULUMI_SKIP_UPDATE_CHECK": "true",
	})

	return nil, nil
}

func (p *azureProvider) Create(ctx context.Context, progressReporter *util.ProgressReporter) error {
	if !p.initSuccessful {
		return fmt.Errorf("attempted to create with uninitialized provider")
	}
	aksCluster := aks.New(p.toAKSConfig())

	return aksCluster.Up(ctx, progressReporter)
}

func (p *azureProvider) Destroy(ctx context.Context, progressReporter *util.ProgressReporter) error {
	if !p.initSuccessful {
		return fmt.Errorf("attempted to destroy with uninitialized provider")
	}
	aksCluster := aks.New(p.toAKSConfig())

	return aksCluster.Destroy(ctx, progressReporter)
}

func (p *azureProvider) WriteOutputs(ctx context.Context, out io.Writer) error {
	if !p.initSuccessful {
		return fmt.Errorf("attempted to write outputs with uninitialized provider")
	}
	aksCluster := aks.New(p.toAKSConfig())

	return aksCluster.Outputs(ctx, out)
}

func (p *azureProvider) WriteKubeConfig(ctx context.Context, w io.Writer) error {
	if !p.initSuccessful {
		return fmt.Errorf("attempted to write kubeconfig with uninitialized provider")
	}
	aksCluster := aks.New(p.toAKSConfig())

	return aksCluster.KubeConfig(ctx, w)
}

func (p *azureProvider) WriteWireGuardConfig(ctx context.Context, w io.Writer) (bool, error) {
	if !p.initSuccessful {
		return false, fmt.Errorf("attempted to write wireguard config with uninitialized provider")
	}
	aksCluster := aks.New(p.toAKSConfig())

	return aksCluster.WireGuardConfig(ctx, w)
}

func (p *azureProvider) HasNvidiaRuntimeInstalled() bool {
	// Azure AKS doesn't install NVIDIA runtime by default
	// This would need to be implemented if GPU support is added
	return false
}

func (p *azureProvider) toAKSConfig() *aks.Config {
	return &aks.Config{
		Config:          p.cfg,
		ProjectBaseName: p.projectName,
		WorkDirRoot:     p.workDirRoot,
		PulumiHome:      p.pulumiHome,
		Pulumi:          p.pulumi,
		EnvVars:         p.envVars,
	}
}

// Helper functions to get Azure configuration from environment or spec
func (p *azureProvider) getAzureLocation() string {
	// Try to get from spec first, then default
	if location, err := p.spec.GetBatteryConfigField("azure_karpenter", "location"); err == nil {
		if loc, ok := location.(string); ok && loc != "" {
			return loc
		}
	}
	// Default location
	return "East US"
}

func (p *azureProvider) getAzureSubscriptionId() string {
	// Try to get from spec first
	if subId, err := p.spec.GetBatteryConfigField("azure_karpenter", "subscription_id"); err == nil {
		if id, ok := subId.(string); ok && id != "" {
			return id
		}
	}
	// This should be set via Azure CLI or environment variables
	return ""
}

func (p *azureProvider) getAzureTenantId() string {
	// Try to get from spec first
	if tenantId, err := p.spec.GetBatteryConfigField("azure_karpenter", "tenant_id"); err == nil {
		if id, ok := tenantId.(string); ok && id != "" {
			return id
		}
	}
	// This should be set via Azure CLI or environment variables
	return ""
}

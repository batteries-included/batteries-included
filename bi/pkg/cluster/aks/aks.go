package aks

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/netip"
	"os"
	"path"
	"strconv"

	"bi/pkg/cluster/util"
	"bi/pkg/wireguard"

	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/auto/optdestroy"
	"github.com/pulumi/pulumi/sdk/v3/go/auto/optup"
	"github.com/pulumi/pulumi/sdk/v3/go/common/tokens"
	"github.com/pulumi/pulumi/sdk/v3/go/common/workspace"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
	"k8s.io/client-go/tools/clientcmd"
	clientcmdapi "k8s.io/client-go/tools/clientcmd/api"
)

var (
	P_BOOL_PTR_FALSE = pulumi.BoolPtr(false)
	P_BOOL_PTR_TRUE  = pulumi.BoolPtr(true)
	P_STR_ALLOW      = pulumi.String("Allow")
	P_STR_DENY       = pulumi.String("Deny")
	P_STR_TCP        = pulumi.String("Tcp")
	P_STR_UDP        = pulumi.String("Udp")
	P_STR_ICMP       = pulumi.String("Icmp")
	P_STR_ASTERISK   = pulumi.String("*")
)

type Config struct {
	ProjectBaseName,
	Slug,
	WorkDirRoot string

	Config     auto.ConfigMap
	PulumiHome auto.LocalWorkspaceOption
	Pulumi     auto.LocalWorkspaceOption
	EnvVars    auto.LocalWorkspaceOption
}

type aks struct {
	cfg     *Config
	pConfig *util.PulumiConfig

	outputs map[string]auto.OutputMap
}

func New(cfg *Config) *aks {
	return &aks{cfg: cfg, outputs: make(map[string]auto.OutputMap)}
}

type runnable interface {
	withConfig(*util.PulumiConfig) error
	withOutputs(map[string]auto.OutputMap) error
	run(*pulumi.Context) error
}

type component struct {
	name string
	runnable
}

// Azure AKS components in deployment order
var components = []component{
	{"resourcegroup", &resourceGroupConfig{}},
	{"vnet", &vnetConfig{}},
	{"gateway", &gatewayConfig{}},
	{"cluster", &clusterConfig{}},
	{"loadbalancer", &loadBalancerConfig{}},
	{"autoscaler", &autoscalerConfig{}},
	{"postgres", &cnpgConfig{}},
}

func (a *aks) Up(ctx context.Context, progressReporter *util.ProgressReporter) error {
	pConfig, err := util.ParsePulumiConfig(a.cfg.Config)
	if err != nil {
		return fmt.Errorf("failed to parse pulumi config: %w", err)
	}

	a.pConfig = pConfig

	for _, cmpnt := range components {
		stack, err := a.createStack(ctx, cmpnt.name, cmpnt.run)
		if err != nil {
			return fmt.Errorf("failed to create component stack %s: %w", cmpnt.name, err)
		}

		if err := a.configure(ctx, stack, cmpnt); err != nil {
			return fmt.Errorf("failed to configure component %s: %w", cmpnt.name, err)
		}

		if err := cmpnt.withOutputs(a.outputs); err != nil {
			return fmt.Errorf("failed to set outputs for component %s: %w", cmpnt.name, err)
		}

		if _, err := stack.Refresh(ctx); err != nil {
			return fmt.Errorf("failed to refresh stack: %w", err)
		}

		upOpts := []optup.Option{
			optup.ProgressStreams(util.DebugLogWriter(ctx, slog.Default())),
			optup.SuppressProgress(), // No progress dots
		}

		if progressReporter != nil {
			upOpts = append(upOpts, optup.EventStreams(progressReporter.ForPulumiEvents(cmpnt.name, false)))
		}

		res, err := stack.Up(ctx, upOpts...)
		if err != nil {
			return fmt.Errorf("failed to create or update resources: %w", err)
		}

		a.outputs[cmpnt.name] = res.Outputs
	}

	return nil
}

func (a *aks) Destroy(ctx context.Context, progressReporter *util.ProgressReporter) error {
	pConfig, err := util.ParsePulumiConfig(a.cfg.Config)
	if err != nil {
		return fmt.Errorf("failed to parse pulumi config: %w", err)
	}

	a.pConfig = pConfig

	// Get outputs for all components first
	stacks := make(map[string]auto.Stack)
	for _, cmpnt := range components {
		stack, err := a.createStack(ctx, cmpnt.name, cmpnt.run)
		if err != nil {
			return fmt.Errorf("failed to create component stack %s: %w", cmpnt.name, err)
		}

		if err := a.configure(ctx, stack, cmpnt); err != nil {
			return fmt.Errorf("failed to configure component %s: %w", cmpnt.name, err)
		}

		out, err := stack.Outputs(ctx)
		if err != nil {
			return fmt.Errorf("failed to get outputs for component %s: %w", cmpnt.name, err)
		}
		a.outputs[cmpnt.name] = out
		stacks[cmpnt.name] = stack
	}

	// Destroy components in reverse order
	for i := range components {
		cmpnt := components[len(components)-1-i]
		stack := stacks[cmpnt.name]

		if err := cmpnt.withOutputs(a.outputs); err != nil {
			return fmt.Errorf("failed to set outputs for component %s: %w", cmpnt.name, err)
		}

		if _, err := stack.Refresh(ctx); err != nil {
			return fmt.Errorf("failed to refresh stack: %w", err)
		}

		destroyOpts := []optdestroy.Option{
			optdestroy.ProgressStreams(util.DebugLogWriter(ctx, slog.Default())),
			optdestroy.SuppressProgress(), // No progress dots
		}

		if progressReporter != nil {
			destroyOpts = append(destroyOpts, optdestroy.EventStreams(progressReporter.ForPulumiEvents(cmpnt.name, true)))
		}

		if _, err := stack.Destroy(ctx, destroyOpts...); err != nil {
			return fmt.Errorf("failed to delete resources: %w", err)
		}
	}

	return nil
}

func (a *aks) Outputs(ctx context.Context, out io.Writer) error {
	pConfig, err := util.ParsePulumiConfig(a.cfg.Config)
	if err != nil {
		return fmt.Errorf("failed to parse pulumi config: %w", err)
	}

	a.pConfig = pConfig

	for _, cmpnt := range components {
		stack, err := a.createStack(ctx, cmpnt.name, cmpnt.run)
		if err != nil {
			return fmt.Errorf("failed to create component stack %s: %w", cmpnt.name, err)
		}

		if err := a.configure(ctx, stack, cmpnt); err != nil {
			return fmt.Errorf("failed to configure component %s: %w", cmpnt.name, err)
		}

		outputs, err := stack.Outputs(ctx)
		if err != nil {
			return fmt.Errorf("failed to get pulumi outputs: %w", err)
		}
		a.outputs[cmpnt.name] = outputs
	}

	if err := json.NewEncoder(out).Encode(a.outputs); err != nil {
		return fmt.Errorf("failed to marshal and write outputs: %w", err)
	}

	return nil
}

func (a *aks) KubeConfig(ctx context.Context, w io.Writer) error {
	// Fetch the outputs from the Pulumi state (if needed).
	if len(a.outputs) == 0 {
		if err := a.Outputs(ctx, io.Discard); err != nil {
			return fmt.Errorf("failed to load pulumi outputs: %w", err)
		}
	}

	clusterName := a.outputs["cluster"]["name"].Value.(string)
	kubeconfig := a.outputs["cluster"]["kubeconfig"].Value.(string)

	// Get the path to the current processes executable.
	cmdPath, err := os.Executable()
	if err != nil {
		return fmt.Errorf("failed to get executable path: %w", err)
	}

	// Parse the kubeconfig to modify the auth method
	config, err := clientcmd.Load([]byte(kubeconfig))
	if err != nil {
		return fmt.Errorf("failed to parse kubeconfig: %w", err)
	}

	// Replace the auth method with our custom Azure token command
	for _, authInfo := range config.AuthInfos {
		authInfo.Token = ""
		authInfo.Exec = &clientcmdapi.ExecConfig{
			APIVersion: "client.authentication.k8s.io/v1beta1",
			Command:    cmdPath,
			Args: []string{
				"azure",
				"get-token",
				"--cluster-name=" + clusterName,
				a.cfg.Slug,
			},
		}
	}

	buf, err := clientcmd.Write(*config)
	if err != nil {
		return fmt.Errorf("failed to marshal kubeconfig: %w", err)
	}

	if _, err := w.Write(buf); err != nil {
		return fmt.Errorf("failed to write kubeconfig: %w", err)
	}

	return nil
}

func (a *aks) WireGuardConfig(ctx context.Context, w io.Writer) (bool, error) {
	// Fetch the outputs from the Pulumi state (if needed).
	if len(a.outputs) == 0 {
		if err := a.Outputs(ctx, io.Discard); err != nil {
			return true, err
		}
	}

	gwEndpoint := net.JoinHostPort(a.outputs["gateway"]["publicIP"].Value.(string),
		strconv.Itoa(int(a.outputs["gateway"]["publicPort"].Value.(float64))))

	_, vnetSubnet, err := net.ParseCIDR(a.outputs["vnet"]["addressSpace"].Value.(string))
	if err != nil {
		return true, fmt.Errorf("error parsing vnet subnet: %w", err)
	}

	gw := wireguard.Gateway{
		PrivateKey: a.outputs["gateway"]["wgGatewayPrivateKey"].Value.(string),
		Address:    netip.MustParseAddr(a.outputs["gateway"]["wgGatewayAddress"].Value.(string)),
		Endpoint:   gwEndpoint,
		// Azure DNS resolver
		Nameservers: []netip.Addr{
			netip.MustParseAddr("168.63.129.16"),
		},
		VPCSubnets: []*net.IPNet{vnetSubnet},
	}

	installerClient := wireguard.Client{
		Gateway:    &gw,
		Name:       "installer",
		PrivateKey: a.outputs["gateway"]["wgClientPrivateKey"].Value.(string),
		Address:    netip.MustParseAddr(a.outputs["gateway"]["wgClientAddress"].Value.(string)),
	}

	if err := installerClient.WriteConfig(w); err != nil {
		return true, fmt.Errorf("error writing wireguard config: %w", err)
	}

	return true, nil
}

// createStack creates the stack with the given program
func (a *aks) createStack(ctx context.Context, name string, prog pulumi.RunFunc) (auto.Stack, error) {
	var s auto.Stack
	projectName := fmt.Sprintf("%s-%s", a.cfg.ProjectBaseName, name)
	workDir := path.Join(a.cfg.WorkDirRoot, name)

	if err := os.MkdirAll(workDir, 0o700); err != nil {
		return s, err
	}

	ws, err := auto.NewLocalWorkspace(ctx,
		a.cfg.PulumiHome,
		a.cfg.Pulumi,
		a.cfg.EnvVars,
		auto.WorkDir(workDir),
		auto.Project(workspace.Project{
			Name:    tokens.PackageName(projectName),
			Runtime: workspace.NewProjectRuntimeInfo("go", nil),
			Backend: &workspace.ProjectBackend{URL: fmt.Sprintf("file://%s", workDir)},
		}),
		auto.Program(prog),
	)
	if err != nil {
		return s, fmt.Errorf("failed to create workspace: %w", err)
	}

	stackName := auto.FullyQualifiedStackName("organization", projectName, a.cfg.Slug)
	s, err = auto.UpsertStack(ctx, stackName, ws)
	if err != nil {
		return s, fmt.Errorf("failed to create stack: %w", err)
	}

	return s, nil
}

func (a *aks) configure(ctx context.Context, s auto.Stack, c component) error {
	// we need the config set in the stack for e.g. providers
	if err := s.SetAllConfig(ctx, a.cfg.Config); err != nil {
		return fmt.Errorf("failed to set config: %w", err)
	}

	// we create the component with the config to avoid having to re-read what we just put on disk
	if err := c.withConfig(a.pConfig); err != nil {
		return fmt.Errorf("failed to set component config: %w", err)
	}

	return nil
}
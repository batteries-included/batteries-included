package eks

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/netip"
	"os"
	"path"
	"regexp"
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
	P_BOOL_PTR_FALSE                       = pulumi.BoolPtr(false)
	P_BOOL_PTR_TRUE                        = pulumi.BoolPtr(true)
	P_STR_ALLOW                            = pulumi.String("Allow")
	P_STR_ARR_EC2_AMAZONAWS_COM            = pulumi.ToStringArray([]string{"ec2.amazonaws.com"})
	P_STR_ARR_EKS_AMAZONAWS_COM            = pulumi.ToStringArray([]string{"eks.amazonaws.com"})
	P_STR_ARR_ELB_AMAZONAWS_COM            = pulumi.ToStringArray([]string{"elasticloadbalancing.amazonaws.com"})
	P_STR_ARR_FALSE                        = pulumi.ToStringArray([]string{"false"})
	P_STR_ARR_OWNED                        = pulumi.ToStringArray([]string{"owned"})
	P_STR_ARR_STS_AMAZONAWS_COM            = pulumi.ToStringArray([]string{"sts.amazonaws.com"})
	P_STR_ARR_STS_ASSUME_ROLE              = pulumi.ToStringArray([]string{"sts:AssumeRole"})
	P_STR_ARR_STS_ASSUME_ROLE_WEB_IDENTITY = pulumi.ToStringArray([]string{"sts:AssumeRoleWithWebIdentity"})
	P_STR_ARR_TRUE                         = pulumi.ToStringArray([]string{"true"})
	P_STR_ARR_WILDCARD                     = pulumi.ToStringArray([]string{"*"})
	P_STR_AWS                              = pulumi.String("AWS")
	P_STR_DENY                             = pulumi.String("Deny")
	P_STR_FALSE                            = pulumi.String("false")
	P_STR_FEDERATED                        = pulumi.String("Federated")
	P_STR_ICMP                             = pulumi.String("icmp")
	P_STR_NULL                             = pulumi.String("Null")
	P_STR_SERVICE                          = pulumi.String("Service")
	P_STR_STRING_EQUALS                    = pulumi.String("StringEquals")
	P_STR_STRING_LIKE                      = pulumi.String("StringLike")
	P_STR_TCP                              = pulumi.String("tcp")
	P_STR_TRUE                             = pulumi.String("true")
	P_STR_UDP                              = pulumi.String("udp")
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

type eks struct {
	cfg     *Config
	pConfig *util.PulumiConfig

	outputs map[string]auto.OutputMap
}

func New(cfg *Config) *eks {
	return &eks{cfg: cfg, outputs: make(map[string]auto.OutputMap)}
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

// this kind of stinks a map would be more convenient but they are specifically
// unordered in go and we need these to run in order
var components = []component{
	{"vpc", &vpcConfig{}},
	{"gateway", &gatewayConfig{}},
	{"cluster", &clusterConfig{}},
	{"lbcontroller", &lbControllerConfig{}},
	{"karpenter", &karpenterConfig{}},
	{"postgres", &cnpgConfig{}},
}

func (e *eks) Up(ctx context.Context, progressReporter *util.ProgressReporter) error {
	pConfig, err := util.ParsePulumiConfig(e.cfg.Config)
	if err != nil {
		return fmt.Errorf("failed to parse pulumi config: %w", err)
	}

	e.pConfig = pConfig

	for _, cmpnt := range components {
		stack, err := e.createStack(ctx, cmpnt.name, cmpnt.run)
		if err != nil {
			return fmt.Errorf("failed to create component stack %s: %w", cmpnt.name, err)
		}

		if err := e.configure(ctx, stack, cmpnt); err != nil {
			return fmt.Errorf("failed to configure component %s: %w", cmpnt.name, err)
		}

		if err := cmpnt.withOutputs(e.outputs); err != nil {
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

		e.outputs[cmpnt.name] = res.Outputs
	}

	return nil
}

func (e *eks) Destroy(ctx context.Context, progressReporter *util.ProgressReporter) error {
	pConfig, err := util.ParsePulumiConfig(e.cfg.Config)
	if err != nil {
		return fmt.Errorf("failed to parse pulumi config: %w", err)
	}

	e.pConfig = pConfig

	// we need to get the outputs for the previous components first
	// so create all the stacks and get all of the outputs
	stacks := make(map[string]auto.Stack)
	for _, cmpnt := range components {
		stack, err := e.createStack(ctx, cmpnt.name, cmpnt.run)
		if err != nil {
			return fmt.Errorf("failed to create component stack %s: %w", cmpnt.name, err)
		}

		if err := e.configure(ctx, stack, cmpnt); err != nil {
			return fmt.Errorf("failed to configure component %s: %w", cmpnt.name, err)
		}

		out, err := stack.Outputs(ctx)
		if err != nil {
			return fmt.Errorf("failed to get outputs for component %s: %w", cmpnt.name, err)
		}
		e.outputs[cmpnt.name] = out
		stacks[cmpnt.name] = stack
	}

	// then work backwards to destroy each stack
	for i := range components {
		cmpnt := components[len(components)-1-i]
		stack := stacks[cmpnt.name]

		if err := cmpnt.withOutputs(e.outputs); err != nil {
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

	// TODO(jdt): do a final destroy on a new stack that cleans up any dangling
	// resources (looking at you karpenter!)

	return nil
}

func (e *eks) Outputs(ctx context.Context, out io.Writer) error {
	pConfig, err := util.ParsePulumiConfig(e.cfg.Config)
	if err != nil {
		return fmt.Errorf("failed to parse pulumi config: %w", err)
	}

	e.pConfig = pConfig

	for _, cmpnt := range components {
		stack, err := e.createStack(ctx, cmpnt.name, cmpnt.run)
		if err != nil {
			return fmt.Errorf("failed to create component stack %s: %w", cmpnt.name, err)
		}

		if err := e.configure(ctx, stack, cmpnt); err != nil {
			return fmt.Errorf("failed to configure component %s: %w", cmpnt.name, err)
		}

		out, err := stack.Outputs(ctx)
		if err != nil {
			return fmt.Errorf("failed to get pulumi outputs: %w", err)
		}
		e.outputs[cmpnt.name] = out
	}

	if err := json.NewEncoder(out).Encode(e.outputs); err != nil {
		return fmt.Errorf("failed to marshal and write outputs: %w", err)
	}

	return nil
}

func (e *eks) KubeConfig(ctx context.Context, w io.Writer) error {
	// Fetch the outputs from the Pulumi state (if needed).
	if len(e.outputs) == 0 {
		if err := e.Outputs(ctx, io.Discard); err != nil {
			return fmt.Errorf("failed to load pulumi outputs: %w", err)
		}
	}

	clusterName := e.outputs["cluster"]["name"].Value.(string)

	// The certificate authority data is base64 encoded in the output (for some reason).
	certificateAuthorityData, err := base64.StdEncoding.DecodeString(e.outputs["cluster"]["certificateAuthority"].Value.(string))
	if err != nil {
		return fmt.Errorf("error decoding ca data: %w", err)
	}

	// Get the path to the current processes executable.
	cmdPath, err := os.Executable()
	if err != nil {
		return fmt.Errorf("failed to get executable path: %w", err)
	}

	endpoint := e.outputs["cluster"]["endpoint"].Value.(string)

	// Get the region from the cluster endpoint.
	re := regexp.MustCompile(`\.([^.]+)\.eks\.amazonaws\.com`)
	matches := re.FindStringSubmatch(endpoint)
	if len(matches) != 2 {
		return fmt.Errorf("failed to extract region from endpoint: %s", endpoint)
	}
	region := matches[1]

	config := clientcmdapi.Config{
		Clusters: map[string]*clientcmdapi.Cluster{
			clusterName: {
				Server:                   endpoint,
				CertificateAuthorityData: certificateAuthorityData,
			},
		},
		AuthInfos: map[string]*clientcmdapi.AuthInfo{
			"installer": {
				// We implement get-token outselves, so that we don't require the user to have the aws cli installed.
				Exec: &clientcmdapi.ExecConfig{
					APIVersion: "client.authentication.k8s.io/v1beta1",
					Command:    cmdPath,
					Args: []string{
						"aws",
						"get-token",
						"--region=" + region,
						e.cfg.Slug,
						clusterName,
					},
				},
			},
		},
		Contexts: map[string]*clientcmdapi.Context{
			clusterName: {
				Cluster:  clusterName,
				AuthInfo: "installer",
			},
		},
		CurrentContext: clusterName,
	}

	buf, err := clientcmd.Write(config)
	if err != nil {
		return fmt.Errorf("failed to marshal kubeconfig: %w", err)
	}

	if _, err := w.Write(buf); err != nil {
		return fmt.Errorf("failed to write kubeconfig: %w", err)
	}

	return nil
}

func (e *eks) WireGuardConfig(ctx context.Context, w io.Writer) (bool, error) {
	// Fetch the outputs from the Pulumi state (if needed).
	if len(e.outputs) == 0 {
		if err := e.Outputs(ctx, io.Discard); err != nil {
			return true, err
		}
	}

	gwEndpoint := net.JoinHostPort(e.outputs["gateway"]["publicIP"].Value.(string),
		strconv.Itoa(int(e.outputs["gateway"]["publicPort"].Value.(float64))))

	_, vpcSubnet, err := net.ParseCIDR(e.outputs["vpc"]["cidrBlock"].Value.(string))
	if err != nil {
		return true, fmt.Errorf("error parsing vpc subnet: %w", err)
	}

	gw := wireguard.Gateway{
		PrivateKey: e.outputs["gateway"]["wgGatewayPrivateKey"].Value.(string),
		Address:    netip.MustParseAddr(e.outputs["gateway"]["wgGatewayAddress"].Value.(string)),
		Endpoint:   gwEndpoint,
		// Route53 static resolver addresses.
		// See: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html#AmazonDNS
		Nameservers: []netip.Addr{
			netip.MustParseAddr("169.254.169.253"),
		},
		VPCSubnets: []*net.IPNet{vpcSubnet},
	}

	installerClient := wireguard.Client{
		Gateway:    &gw,
		Name:       "installer",
		PrivateKey: e.outputs["gateway"]["wgClientPrivateKey"].Value.(string),
		Address:    netip.MustParseAddr(e.outputs["gateway"]["wgClientAddress"].Value.(string)),
	}

	if err := installerClient.WriteConfig(w); err != nil {
		return true, fmt.Errorf("error writing wireguard config: %w", err)
	}

	return true, nil
}

// createStack creates the stack with the given program
func (e *eks) createStack(ctx context.Context, name string, prog pulumi.RunFunc) (auto.Stack, error) {
	var s auto.Stack
	projectName := fmt.Sprintf("%s-%s", e.cfg.ProjectBaseName, name)
	workDir := path.Join(e.cfg.WorkDirRoot, name)

	if err := os.MkdirAll(workDir, 0o700); err != nil {
		return s, err
	}

	ws, err := auto.NewLocalWorkspace(ctx,
		e.cfg.PulumiHome,
		e.cfg.Pulumi,
		e.cfg.EnvVars,
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

	stackName := auto.FullyQualifiedStackName("organization", projectName, e.cfg.Slug)
	s, err = auto.UpsertStack(ctx, stackName, ws)
	if err != nil {
		return s, fmt.Errorf("failed to create stack: %w", err)
	}

	return s, nil
}

func (e *eks) configure(ctx context.Context, s auto.Stack, c component) error {
	// we need the config set in the stack for e.g. providers
	if err := s.SetAllConfig(ctx, e.cfg.Config); err != nil {
		return fmt.Errorf("failed to set config: %w", err)
	}

	// we create the component with the config to avoid having to re-read what we just put on disk
	if err := c.withConfig(e.pConfig); err != nil {
		return fmt.Errorf("failed to set component config: %w", err)
	}

	return nil
}

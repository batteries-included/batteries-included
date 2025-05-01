package cluster

import (
	"context"
	"fmt"
	"io"
	"path"

	"bi/pkg/cluster/eks"
	"bi/pkg/cluster/util"
	"bi/pkg/specs"

	"github.com/adrg/xdg"
	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/common/tokens"
	"github.com/pulumi/pulumi/sdk/v3/go/common/workspace"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

const (
	homeDir = "home"
	workDir = "work"
)

type pulumiProvider struct {
	initSuccessful bool
	spec           *specs.InstallSpec

	cfg auto.ConfigMap
	projectName,
	workDirRoot string

	pulumiHome auto.LocalWorkspaceOption
	pulumi     auto.LocalWorkspaceOption
	envVars    auto.LocalWorkspaceOption
}

func NewPulumiProvider(spec *specs.InstallSpec) Provider {
	return &pulumiProvider{
		projectName: "bi",
		spec:        spec,
	}
}

func (p *pulumiProvider) Init(ctx context.Context) error {
	_, err := p.configure(ctx)
	if err != nil {
		return fmt.Errorf("failed to configure pulumi provider: %w", err)
	}

	p.initSuccessful = true

	return nil
}

// configure sets up configuration common to all substacks
func (p *pulumiProvider) configure(ctx context.Context) (auto.Workspace, error) {
	stackName := auto.FullyQualifiedStackName("organization", p.projectName, p.spec.Slug)

	tags, err := newTags(stackName)
	if err != nil {
		return nil, fmt.Errorf("failed to create tags for %s: %w", stackName, err)
	}

	baseNS, err := p.spec.GetBatteryConfigField("battery_core", "base_namespace")
	if err != nil {
		return nil, fmt.Errorf("failed to get base namespace: %w", err)
	}

	p.cfg = auto.ConfigMap{
		"aws:defaultTags":        {Value: tags},
		"aws:region":             {Value: "us-east-2"},
		"cluster:amiType":        {Value: "AL2_x86_64"},
		"cluster:capacityType":   {Value: "ON_DEMAND"},
		"cluster:desiredSize":    {Value: "2"},
		"cluster:instanceType":   {Value: "t3a.medium"},
		"cluster:maxSize":        {Value: "4"},
		"cluster:minSize":        {Value: "2"},
		"cluster:name":           {Value: p.spec.Slug},
		"cluster:version":        {Value: "1.32"},
		"cluster:volumeSize":     {Value: "20"},
		"cluster:volumeType":     {Value: "gp3"},
		"gateway:cidrBlock":      {Value: "100.64.250.0/24"},
		"gateway:generateSSHKey": {Value: "false"},
		"gateway:instanceType":   {Value: "t3a.micro"},
		"gateway:port":           {Value: "51820"},
		"gateway:volumeSize":     {Value: "12"},
		"gateway:volumeType":     {Value: "gp3"},
		"karpenter:namespace":    {Value: baseNS.(string)},
		"lbcontroller:namespace": {Value: baseNS.(string)},
		"vpc:cidrBlock":          {Value: "100.64.0.0/16"},
	}

	dirs, err := p.makeDirs()
	if err != nil {
		return nil, fmt.Errorf("failed to create necessary directories: %w", err)
	}

	cmd, err := auto.InstallPulumiCommand(ctx, &auto.PulumiCommandOptions{Root: dirs[homeDir], SkipVersionCheck: true})
	if err != nil {
		return nil, fmt.Errorf("failed to download pulumi cli: %w", err)
	}

	p.workDirRoot = dirs[workDir]
	p.pulumi = auto.Pulumi(cmd)
	p.pulumiHome = auto.PulumiHome(dirs[homeDir])
	p.envVars = auto.EnvVars(map[string]string{
		"AUTOMATION_API_SKIP_VERSION_CHECK": "1",
		"PULUMI_CONFIG_PASSPHRASE":          "PASSWORD",
	})

	return p.createWorkspace(ctx)
}

// makeDirs makes the necessary subdirectories under $XDG_STATE_HOME
func (p *pulumiProvider) makeDirs() (map[string]string, error) {
	dirs := make(map[string]string)
	for _, dir := range []string{workDir, homeDir} {
		// "file" is just a placeholder to get it to create the directory
		d, err := xdg.StateFile(path.Join(p.projectName, dir, "file"))
		if err != nil {
			return nil, fmt.Errorf("failed to create necessary directory: %w", err)
		}

		dirs[dir] = path.Dir(d)
	}
	return dirs, nil
}

// createWorkspace creates a "dummy" workspace for installing plugins and setting up a "dummy" stack
func (p *pulumiProvider) createWorkspace(ctx context.Context) (auto.Workspace, error) {
	return auto.NewLocalWorkspace(ctx,
		p.pulumiHome,
		p.pulumi,
		p.envVars,
		auto.WorkDir(p.workDirRoot),
		auto.Project(workspace.Project{
			Name:    tokens.PackageName(p.projectName),
			Runtime: workspace.NewProjectRuntimeInfo("go", nil),
			Backend: &workspace.ProjectBackend{URL: fmt.Sprintf("file://%s", p.workDirRoot)},
		}),
		auto.Program(func(ctx *pulumi.Context) error { return nil }),
	)
}

func (p *pulumiProvider) Create(ctx context.Context, progressReporter *util.ProgressReporter) error {
	if !p.initSuccessful {
		return fmt.Errorf("attempted to create with uninitialized provider")
	}
	eks := eks.New(p.toEKSConfig())

	return eks.Up(ctx, progressReporter)
}

func (p *pulumiProvider) Destroy(ctx context.Context, progressReporter *util.ProgressReporter) error {
	if !p.initSuccessful {
		return fmt.Errorf("attempted to destroy with uninitialized provider")
	}
	eks := eks.New(p.toEKSConfig())

	return eks.Destroy(ctx, progressReporter)
}

func (p *pulumiProvider) WriteOutputs(ctx context.Context, out io.Writer) error {
	if !p.initSuccessful {
		return fmt.Errorf("attempted to destroy with uninitialized provider")
	}
	eks := eks.New(p.toEKSConfig())

	return eks.Outputs(ctx, out)
}

func (p *pulumiProvider) WriteKubeConfig(ctx context.Context, w io.Writer) error {
	if !p.initSuccessful {
		return fmt.Errorf("attempted to export kubeconfig with uninitialized provider")
	}

	eks := eks.New(p.toEKSConfig())

	return eks.KubeConfig(ctx, w)
}

func (p *pulumiProvider) WriteWireGuardConfig(ctx context.Context, w io.Writer) (bool, error) {
	if !p.initSuccessful {
		return false, fmt.Errorf("attempted to export wireguard config with uninitialized provider")
	}

	eks := eks.New(p.toEKSConfig())

	return eks.WireGuardConfig(ctx, w)

}

func (p *pulumiProvider) toEKSConfig() *eks.Config {
	return &eks.Config{
		ProjectBaseName: p.projectName,
		Slug:            p.spec.Slug,
		WorkDirRoot:     p.workDirRoot,

		Config:     p.cfg,
		PulumiHome: p.pulumiHome,
		Pulumi:     p.pulumi,
		EnvVars:    p.envVars,
	}
}

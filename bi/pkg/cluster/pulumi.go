package cluster

import (
	"context"
	"fmt"
	"io"
	"path"

	"bi/pkg/cluster/eks"
	"bi/pkg/cluster/util"

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

	cfg auto.ConfigMap
	projectName,
	slug,
	workDirRoot string

	pulumiHome auto.LocalWorkspaceOption
	pulumi     auto.LocalWorkspaceOption
	envVars    auto.LocalWorkspaceOption
}

func NewPulumiProvider(slug string) Provider {
	return &pulumiProvider{
		projectName: "bi",
		slug:        slug,
	}
}

func (p *pulumiProvider) Init(ctx context.Context) error {
	ws, err := p.configure(ctx)
	if err != nil {
		return fmt.Errorf("failed to configure pulumi provider: %w", err)
	}

	// add plugins that need to be installed here
	plugins := map[string]string{
		"aws":       "v6.54.2",
		"cloudinit": "v1.4.7",
		"tls":       "v5.0.7",
	}
	if err := p.installPlugins(ctx, ws, plugins); err != nil {
		return fmt.Errorf("failed to install necessary pulumi plugins: %w", err)
	}

	p.initSuccessful = true

	return nil
}

// configure sets up configuration common to all substacks and handles installing the plugins necessary
func (p *pulumiProvider) configure(ctx context.Context) (auto.Workspace, error) {
	stackName := auto.FullyQualifiedStackName("organization", p.projectName, p.slug)

	tags, err := newTags(stackName)
	if err != nil {
		return nil, fmt.Errorf("failed to create tags for %s: %w", stackName, err)
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
		"cluster:name":           {Value: p.slug},
		"cluster:version":        {Value: "1.31"},
		"cluster:volumeSize":     {Value: "20"},
		"cluster:volumeType":     {Value: "gp3"},
		"gateway:cidrBlock":      {Value: "100.64.250.0/24"},
		"gateway:generateSSHKey": {Value: "false"},
		"gateway:instanceType":   {Value: "t3a.micro"},
		"gateway:port":           {Value: "51820"},
		"gateway:volumeSize":     {Value: "12"},
		"gateway:volumeType":     {Value: "gp3"},
		"karpenter:namespace":    {Value: "battery-base"}, // TODO(jdt): get from install spec
		"lbcontroller:namespace": {Value: "battery-base"}, // TODO(jdt): get from install spec
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

// installPlugins installs the provided plugins
func (p *pulumiProvider) installPlugins(ctx context.Context, ws auto.Workspace, plugins map[string]string) error {
	for plugin, version := range plugins {
		if err := ws.InstallPlugin(ctx, plugin, version); err != nil {
			return fmt.Errorf("failed to install necessary plugin: %s: %w", plugin, err)
		}
	}

	return nil
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

func (p *pulumiProvider) Outputs(ctx context.Context, out io.Writer) error {
	if !p.initSuccessful {
		return fmt.Errorf("attempted to destroy with uninitialized provider")
	}
	eks := eks.New(p.toEKSConfig())

	return eks.Outputs(ctx, out)
}

func (p *pulumiProvider) KubeConfig(ctx context.Context, w io.Writer) error {
	if !p.initSuccessful {
		return fmt.Errorf("attempted to export kubeconfig with uninitialized provider")
	}

	eks := eks.New(p.toEKSConfig())

	return eks.KubeConfig(ctx, w)
}

func (p *pulumiProvider) WireGuardConfig(ctx context.Context, w io.Writer) (bool, error) {
	if !p.initSuccessful {
		return false, fmt.Errorf("attempted to export wireguard config with uninitialized provider")
	}

	eks := eks.New(p.toEKSConfig())

	return eks.WireGuardConfig(ctx, w)

}

func (p *pulumiProvider) toEKSConfig() *eks.Config {
	return &eks.Config{
		ProjectBaseName: p.projectName,
		Slug:            p.slug,
		WorkDirRoot:     p.workDirRoot,

		Config:     p.cfg,
		PulumiHome: p.pulumiHome,
		Pulumi:     p.pulumi,
		EnvVars:    p.envVars,
	}
}

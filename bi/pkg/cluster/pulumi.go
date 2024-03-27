package cluster

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"os/user"
	"path"

	"bi/pkg/cluster/eks"

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

	cfg         auto.ConfigMap
	projectName string
	workDirRoot string

	pulumiHome auto.LocalWorkspaceOption
	pulumi     auto.LocalWorkspaceOption
	envVars    auto.LocalWorkspaceOption
}

func NewPulumiProvider() provider {
	return &pulumiProvider{}
}

func (p *pulumiProvider) Init(ctx context.Context) error {
	ws, err := p.configure(ctx)
	if err != nil {
		return err
	}

	// add plugins that need to be installed here
	plugins := map[string]string{
		"aws":       "v6.22.2",
		"cloudinit": "v1.4.1",
		"tls":       "v5.0.0",
	}
	if err := p.installPlugins(ctx, ws, plugins); err != nil {
		return err
	}

	p.initSuccessful = true

	return nil
}

// configure sets up configuration common to all substacks and handles installing the plugins necessary
func (p *pulumiProvider) configure(ctx context.Context) (auto.Workspace, error) {
	p.projectName = "bi"

	// TODO(cleanup):
	stackName := auto.FullyQualifiedStackName("organization", p.projectName, "test")

	tags, err := newTags(stackName)
	if err != nil {
		return nil, err
	}

	// NOTE(jdt): this is temporary so that multiple folks can create clusters w/o conflict?
	user, err := user.Current()
	if err != nil {
		return nil, err
	}

	p.cfg = auto.ConfigMap{
		"aws:defaultTags":      {Value: tags},
		"aws:region":           {Value: "us-east-2"},
		"cluster:amiType":      {Value: "AL2_x86_64"},
		"cluster:capacityType": {Value: "ON_DEMAND"},
		"cluster:desiredSize":  {Value: "2"},
		"cluster:instanceType": {Value: "t3a.medium"},
		"cluster:maxSize":      {Value: "4"},
		"cluster:minSize":      {Value: "2"},
		"cluster:name":         {Value: user.Username},
		"cluster:version":      {Value: "1.29"},
		"cluster:volumeSize":   {Value: "20"},
		"cluster:volumeType":   {Value: "gp3"},
		"gateway:cidrBlock":    {Value: "100.64.250.0/24"},
		"gateway:generateKey":  {Value: "false"},
		"gateway:instanceType": {Value: "t3a.micro"},
		"gateway:port":         {Value: "51820"},
		"gateway:volumeSize":   {Value: "12"},
		"gateway:volumeType":   {Value: "gp3"},
		"vpc:cidrBlock":        {Value: "100.64.0.0/16"},
	}

	dirs, err := p.makeDirs()
	if err != nil {
		slog.Error("Failed to create necessary directories")
		return nil, err
	}

	cmd, err := auto.InstallPulumiCommand(ctx, &auto.PulumiCommandOptions{Root: dirs[homeDir], SkipVersionCheck: true})
	if err != nil {
		return nil, err
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
		err := ws.InstallPlugin(ctx, plugin, version)
		if err != nil {
			return fmt.Errorf("failed to install necessary plugin: %s: %w", plugin, err)
		}
	}

	return nil
}

func (p *pulumiProvider) Create(ctx context.Context) error {
	if !p.initSuccessful {
		return fmt.Errorf("attempted to create with uninitialized provider")
	}
	eks := eks.New(p.toEKSConfig())

	return eks.Up(ctx)
}

func (p *pulumiProvider) Destroy(ctx context.Context) error {
	if !p.initSuccessful {
		return fmt.Errorf("attempted to destroy with uninitialized provider")
	}
	eks := eks.New(p.toEKSConfig())

	return eks.Destroy(ctx)
}

func (p *pulumiProvider) Outputs(ctx context.Context, out io.Writer) error {
	if !p.initSuccessful {
		return fmt.Errorf("attempted to destroy with uninitialized provider")
	}
	eks := eks.New(p.toEKSConfig())

	return eks.Outputs(ctx, out)
}

func (p *pulumiProvider) toEKSConfig() *eks.Config {
	return &eks.Config{
		ProjectBaseName: p.projectName,
		WorkDirRoot:     p.workDirRoot,

		Config:     p.cfg,
		PulumiHome: p.pulumiHome,
		Pulumi:     p.pulumi,
		EnvVars:    p.envVars,
	}
}

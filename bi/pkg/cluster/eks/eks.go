package eks

import (
	"context"
	"fmt"
	"os"
	"path"

	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/auto/optdestroy"
	"github.com/pulumi/pulumi/sdk/v3/go/auto/optup"
	"github.com/pulumi/pulumi/sdk/v3/go/common/tokens"
	"github.com/pulumi/pulumi/sdk/v3/go/common/workspace"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

type Config struct {
	ProjectBaseName string
	WorkDirRoot     string

	Config     auto.ConfigMap
	PulumiHome auto.LocalWorkspaceOption
	Pulumi     auto.LocalWorkspaceOption
	EnvVars    auto.LocalWorkspaceOption
}

type eks struct {
	cfg *Config

	outputs map[string]auto.OutputMap
}

func New(cfg *Config) *eks {
	return &eks{cfg: cfg, outputs: make(map[string]auto.OutputMap)}
}

type runnable interface {
	withConfig(auto.ConfigMap) error
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
	{"vpc", &vpc{}},
	{"gateway", &gateway{}},
	{"cluster", &cluster{}},
	{"conn", &wgConn{}},
}

func (e *eks) Up(ctx context.Context) error {
	for _, cmpnt := range components {
		stack, err := e.createStack(ctx, cmpnt.name, cmpnt.run)
		if err != nil {
			return err
		}

		if err := e.configure(ctx, stack, cmpnt); err != nil {
			return err
		}

		if err := cmpnt.withOutputs(e.outputs); err != nil {
			return err
		}

		if err := e.refresh(ctx, stack); err != nil {
			return err
		}

		// wire up our update to stream progress to stdout
		stdoutStreamer := optup.ProgressStreams(os.Stdout)

		res, err := stack.Up(ctx, stdoutStreamer)
		if err != nil {
			return err
		}

		e.outputs[cmpnt.name] = res.Outputs
	}

	return nil
}

func (e *eks) Destroy(ctx context.Context) error {
	// we need to get the outputs for the previous components first
	// so create all the stacks and get all of the outputs
	stacks := make(map[string]auto.Stack)
	for _, cmpnt := range components {
		stack, err := e.createStack(ctx, cmpnt.name, cmpnt.run)
		if err != nil {
			return err
		}

		if err := e.configure(ctx, stack, cmpnt); err != nil {
			return err
		}

		out, err := stack.Outputs(ctx)
		if err != nil {
			return err
		}
		e.outputs[cmpnt.name] = out
		stacks[cmpnt.name] = stack
	}

	// then work backwards to destroy each stack
	for i := range components {
		cmpnt := components[len(components)-1-i]
		stack := stacks[cmpnt.name]

		if err := cmpnt.withOutputs(e.outputs); err != nil {
			return err
		}
		if err := e.refresh(ctx, stack); err != nil {
			return err
		}

		// wire up our update to stream progress to stdout
		stdoutStreamer := optdestroy.ProgressStreams(os.Stdout)

		_, err := stack.Destroy(ctx, stdoutStreamer)
		if err != nil {
			return err
		}
	}

	// TODO(jdt): do a final destroy on a new stack that cleans up any dangling
	// resources (looking at you karpenter!)

	return nil
}

// createStack creates the stack with the given program
func (e *eks) createStack(ctx context.Context, name string, prog pulumi.RunFunc) (auto.Stack, error) {
	var s auto.Stack
	projectName := fmt.Sprintf("%s-%s", e.cfg.ProjectBaseName, name)
	workDir := path.Join(e.cfg.WorkDirRoot, name)

	if err := os.MkdirAll(workDir, os.ModePerm); err != nil {
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

	stackName := auto.FullyQualifiedStackName("organization", projectName, "test")
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
	if err := c.withConfig(e.cfg.Config); err != nil {
		return err
	}

	return nil
}

func (e *eks) refresh(ctx context.Context, s auto.Stack) error {
	_, err := s.Refresh(ctx)
	if err != nil {
		return fmt.Errorf("failed to refresh stack: %w", err)
	}
	return nil
}

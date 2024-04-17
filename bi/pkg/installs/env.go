package installs

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"

	"bi/pkg/specs"

	"bi/pkg/cluster"
	"bi/pkg/cluster/kind"

	"github.com/adrg/xdg"
)

// This wraps all the paths and locations for caching data of an install
// the spec is used to tell us what should be running.
type InstallEnv struct {
	// The Slug of the customer install
	Slug            string
	clusterProvider cluster.Provider
	Spec            *specs.InstallSpec
}

// Init Function generate all needed
func (env *InstallEnv) init(ctx context.Context) error {
	slog.Debug("Initializing install", slog.String("slug", env.Slug))
	// Create the install directory in the xdg state home
	err := os.MkdirAll(env.installStateHome(), 0o700)
	if err != nil {
		return fmt.Errorf("error creating install directory: %w", err)
	}

	// Try writing the spec and summary to the install directory
	// Don't overwrite
	err = env.WriteSpec(false)
	if err != nil {
		return fmt.Errorf("error initializing install writing spec: %w", err)
	}

	err = env.WriteSummary(false)
	if err != nil {
		return err
	}

	provider := env.Spec.KubeCluster.Provider

	switch provider {
	case "kind":
		// TODO get this from the config
		clusterName := env.Slug

		env.clusterProvider = kind.NewClusterProvider(slog.Default(), clusterName)
	case "aws":
		env.clusterProvider = cluster.NewPulumiProvider()
	case "provided":
	default:
		slog.Debug("unexpected provider", slog.String("provider", provider))
		return fmt.Errorf("unknown provider")
	}

	if err = env.clusterProvider.Init(ctx); err != nil {
		return fmt.Errorf("error initializing cluster provider: %w", err)
	}

	return nil
}

func NewEnv(ctx context.Context, slugOrUrl string) (*InstallEnv, error) {
	// Check if the slug is a local install
	installEnv, err := readInstallEnv(slugOrUrl)
	if err == nil {
		err = installEnv.init(ctx)
		if err != nil {
			return nil, fmt.Errorf("error initializing install: %w", err)
		}

		return installEnv, nil
	}

	// If there was some other error then return it
	if !os.IsNotExist(err) {
		return nil, fmt.Errorf("error reading install env: %w", err)
	}

	// If the slug is not a local install then try to get the spec from the url
	spec, err := specs.GetSpecFromURL(slugOrUrl)
	if err != nil {
		return nil, fmt.Errorf("error getting spec from url: %w", err)
	}

	installEnv = &InstallEnv{
		Slug: spec.Slug,
		Spec: spec,
	}

	// We got from the url so we should remove everything
	_ = installEnv.Remove()

	err = installEnv.init(ctx)
	if err != nil {
		return nil, fmt.Errorf("error initializing install: %w", err)
	}

	return installEnv, nil
}

func readInstallEnv(slug string) (*InstallEnv, error) {
	specPath := filepath.Join(xdg.StateHome, "bi", "installs", slug, "spec.json")

	spec, err := specs.GetSpecFromURL(specPath)
	if err != nil {
		return nil, err
	}
	slog.Debug("Found install", slog.String("slug", slug), slog.String("spec", specPath))

	return &InstallEnv{
		Slug: slug,
		Spec: spec,
	}, nil
}

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
		env.clusterProvider = kind.NewClusterProvider(slog.Default(), env.Slug)
	case "aws":
		env.clusterProvider = cluster.NewPulumiProvider(env.Slug)
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

func NewEnv(ctx context.Context, slugOrURL string) (*InstallEnv, error) {
	source, installEnv, err := readInstallEnv(slugOrURL)
	if err != nil {
		return nil, err
	}

	if source == "url" {
		// We got from the url so we should remove everything
		_ = installEnv.Remove()
	}

	err = installEnv.init(ctx)
	if err != nil {
		return nil, fmt.Errorf("error initializing install: %w", err)
	}

	return installEnv, nil
}

func readInstallEnv(slugOrURL string) (string, *InstallEnv, error) {
	type potentialPath struct{ source, path string }
	for _, p := range []potentialPath{
		{source: "file", path: filepath.Join(xdg.StateHome, "bi", "installs", slugOrURL, "spec.json")},
		{source: "url", path: slugOrURL},
	} {
		l := slog.With(slog.String("path", p.path), slog.String("source", p.source))

		spec, err := specs.GetSpecFromURL(p.path)
		if err != nil {
			l.Debug("Didn't find install")
			continue
		}
		l.Debug("Found install")
		return p.source, &InstallEnv{Slug: spec.Slug, Spec: spec}, nil
	}

	return "", nil, fmt.Errorf("No spec found")
}

package installs

import (
	"fmt"
	"log/slog"
	"os"
	"path/filepath"

	"bi/pkg/local"
	"bi/pkg/specs"

	"github.com/adrg/xdg"
)

// This wraps all the paths and locations for caching data of an install
// the spec is used to tell us what should be running.
type InstallEnv struct {
	// The Slug of the customer install
	Slug                string
	kindClusterProvider *local.KindClusterProvider
	// TODO pull any pulumi stuff that common for start, stop, and generate keys into here
	Spec *specs.InstallSpec
}

// Init Function generate all needed
func (env *InstallEnv) init() error {
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

	if env.Spec.KubeCluster.Provider == "kind" {
		// TODO get this from the config
		clusterName := env.Slug
		env.kindClusterProvider, err = local.NewKindClusterProvider(clusterName)
		if err != nil {
			return fmt.Errorf("error creating kind cluster provider: %w", err)
		}
	}

	err = env.WriteKubeConfig(false)
	if err != nil {
		return err
	}
	return nil
}

func NewEnv(slugOrUrl string) (*InstallEnv, error) {
	// Check if the slug is a local install
	installEnv, err := readInstallEnv(slugOrUrl)
	if err == nil {
		err = installEnv.init()
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

	err = installEnv.init()
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

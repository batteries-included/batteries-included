package installs

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"

	"bi/pkg/jwt"
	"bi/pkg/specs"

	"bi/pkg/cluster"
	"bi/pkg/cluster/kind"

	"github.com/adrg/xdg"
)

// This wraps all the paths and locations for caching data of an install
// the spec is used to tell us what should be running.
type InstallEnv struct {
	// The Slug of the customer install
	Slug                string
	clusterProvider     cluster.Provider
	Spec                *specs.InstallSpec
	source              string
	nvidiaAutoDiscovery bool
}

func (env *InstallEnv) ClusterProvider() cluster.Provider {
	return env.clusterProvider
}

type envBuilder struct {
	slugOrURL               string
	additionalInsecureHosts []string
	nvidiaAutoDiscovery     bool
	allowTestKeys           bool
}

type envBuilderOption func(*envBuilder)

func WithSlugOrURL(slugOrURL string) envBuilderOption {
	return func(eb *envBuilder) {
		eb.slugOrURL = slugOrURL
	}
}

func WithAdditionalInsecureHosts(hosts []string) envBuilderOption {
	return func(eb *envBuilder) {
		eb.additionalInsecureHosts = hosts
	}
}

func WithNvidiaAutoDiscovery(enabled bool) envBuilderOption {
	return func(eb *envBuilder) {
		eb.nvidiaAutoDiscovery = enabled
	}
}

func WithAllowTestKeys(enabled bool) envBuilderOption {
	return func(eb *envBuilder) {
		eb.allowTestKeys = enabled
	}
}

func NewEnvBuilder(opts ...envBuilderOption) *envBuilder {
	eb := &envBuilder{
		additionalInsecureHosts: []string{},
		nvidiaAutoDiscovery:     true, // Default to enabled
		allowTestKeys:           false,
	}
	for _, cb := range opts {
		cb(eb)
	}
	return eb
}

func (eb *envBuilder) Build(ctx context.Context) (*InstallEnv, error) {
	installEnv, err := eb.readInstallEnv()
	if err != nil {
		return nil, fmt.Errorf("error reading install env: %w", err)
	}

	return installEnv, nil
}

func (eb *envBuilder) readInstallEnv() (*InstallEnv, error) {
	// Create JWT verifier based on allowTestKeys setting
	jwtVerifier := jwt.NewVerifier(eb.allowTestKeys)

	type potentialPath struct{ source, path string }
	for _, p := range []potentialPath{
		{source: "file", path: filepath.Join(xdg.StateHome, "bi", "installs", eb.slugOrURL, "spec.json")},
		{source: "url", path: eb.slugOrURL},
	} {
		l := slog.With(slog.String("path", p.path), slog.String("source", p.source))

		// Create SpecFetcher with JWT verification for remote URLs
		var fetcher *specs.SpecFetcher
		if p.source == "url" {
			fetcher = specs.NewSpecFetcher(
				specs.WithURL(p.path),
				specs.WithAdditionalInsecureHosts(eb.additionalInsecureHosts),
				specs.WithJWTVerifier(jwtVerifier),
			)
		} else {
			// For local files, we can skip JWT verification
			fetcher = specs.NewSpecFetcher(
				specs.WithURL(p.path),
				specs.WithJWTVerifier(jwt.SkipVerification()),
			)
		}

		spec, err := fetcher.Fetch()
		if err != nil {
			l.Debug("Didn't find install", slog.Any("error", err))
			continue
		}
		l.Debug("Found install")
		return &InstallEnv{
			Slug:                spec.Slug,
			Spec:                spec,
			source:              p.source,
			nvidiaAutoDiscovery: eb.nvidiaAutoDiscovery,
		}, nil
	}

	return nil, errors.New("no spec found")
}

// NeedsKubeCleanup returns true if we should remove all resources in an install
func (env *InstallEnv) NeedsKubeCleanup() bool {
	// Returns true if the cluster provider is in [provided, aws, azure]
	provider := env.Spec.KubeCluster.Provider
	if provider != "provided" && provider != "aws" && provider != "azure" {
		return false
	}

	// Do we have a kube config? Eg. we finished bootstrapping.
	_, err := os.Stat(env.KubeConfigPath())
	return err == nil
}

func (env *InstallEnv) Init(ctx context.Context, remove bool) error {
	// since NeedsKubeCleanup is predicated on their being a kube config, allow skipping removal
	if env.source == "url" && remove {
		// We got from the url so we should remove everything
		_ = env.Remove()
	}

	if err := env.init(ctx); err != nil {
		return fmt.Errorf("error initializing install: %w", err)
	}
	return nil
}

func (env *InstallEnv) init(ctx context.Context) error {
	slog.Debug("Initializing install", slog.String("slug", env.Slug))
	// Create the install directory in the xdg state home
	if err := os.MkdirAll(env.InstallStateHome(), 0o700); err != nil {
		return fmt.Errorf("error creating install directory: %w", err)
	}

	// Try writing the spec and summary to the install directory
	// Don't overwrite
	if err := env.WriteSpec(false); err != nil {
		return fmt.Errorf("error checking spec is writeable: %w", err)
	}

	if err := env.WriteSummary(false); err != nil {
		return fmt.Errorf("error checking summary is writeable: %w", err)
	}

	provider := env.Spec.KubeCluster.Provider

	switch provider {
	case "kind":
		needsLocalGateway, err := env.Spec.NeedsLocalGateway()
		if err != nil {
			return fmt.Errorf("error checking if local gateway is needed: %w", err)
		}
		dockerDesktop, _ := kind.IsDockerDesktop(ctx)
		podman, _ := kind.IsPodmanAvailable()

		gatewayEnabled := needsLocalGateway && (dockerDesktop || podman)
		env.clusterProvider = kind.NewClusterProvider(slog.Default(), env.Slug, gatewayEnabled, env.nvidiaAutoDiscovery)
	case "aws":
		env.clusterProvider = cluster.NewPulumiProvider(env.Spec)
	case "azure":
		env.clusterProvider = cluster.NewAzureProvider(env.Spec)
	case "provided":
	default:
		return fmt.Errorf("unknown provider: %s", provider)
	}

	if err := env.clusterProvider.Init(ctx); err != nil {
		return fmt.Errorf("error initializing cluster provider: %w", err)
	}

	return nil
}

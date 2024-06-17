package kind

import (
	"bi/pkg/cluster/util"
	"context"
	"fmt"
	"io"
	"log/slog"

	slogmulti "github.com/samber/slog-multi"
	"sigs.k8s.io/kind/pkg/cluster"
)

const (
	KindImage = "kindest/node:v1.30.0"
)

type KindClusterProvider struct {
	logger       *slog.Logger
	nodeProvider cluster.ProviderOption
	name         string
}

func NewClusterProvider(logger *slog.Logger, name string) *KindClusterProvider {
	return &KindClusterProvider{
		logger: logger,
		name:   name,
	}
}

func (c *KindClusterProvider) Init(ctx context.Context) error {
	var err error
	c.nodeProvider, err = cluster.DetectNodeProvider()
	if err != nil {
		return fmt.Errorf("failed to detect node provider: %w", err)
	}
	if c.nodeProvider == nil {
		return fmt.Errorf("neither docker nor podman are available")
	}

	return nil
}

func (c *KindClusterProvider) Create(ctx context.Context, progressReporter *util.ProgressReporter) error {
	isRunning, err := c.isRunning()
	if err != nil {
		return fmt.Errorf("failed to check if kind cluster is running: %w", err)
	}

	if !isRunning {
		logger := c.logger
		if progressReporter != nil {
			logInterceptor := progressReporter.ForKindCreateLogs()
			defer logInterceptor.(io.Closer).Close()

			logger = slog.New(slogmulti.Fanout(
				c.logger.Handler(),
				logInterceptor,
			))
		}

		providerOpts := []cluster.ProviderOption{
			c.nodeProvider,
			cluster.ProviderWithLogger(&slogAdapter{Logger: logger}),
		}

		kindProvider := cluster.NewProvider(providerOpts...)

		createOpts := []cluster.CreateOption{
			// We'll need to configure the cluster here
			// if customers need to access the docker images.
			cluster.CreateWithNodeImage(KindImage),
			cluster.CreateWithDisplayUsage(false),
			cluster.CreateWithDisplaySalutation(false),
		}

		if err := kindProvider.Create(c.name, createOpts...); err != nil {
			return fmt.Errorf("failed to create kind cluster: %w", err)
		}
	} else {
		c.logger.Debug("Kind cluster already running", slog.String("name", c.name))
	}

	return nil
}

func (c *KindClusterProvider) Destroy(ctx context.Context, _ *util.ProgressReporter) error {
	isRunning, err := c.isRunning()
	if err != nil {
		return fmt.Errorf("failed to check if kind cluster is running: %w", err)
	}

	if isRunning {
		providerOpts := []cluster.ProviderOption{
			c.nodeProvider,
			cluster.ProviderWithLogger(&slogAdapter{Logger: c.logger}),
		}

		kindProvider := cluster.NewProvider(providerOpts...)

		if err := kindProvider.Delete(c.name, ""); err != nil {
			return fmt.Errorf("failed to delete existing kind cluster: %w", err)
		}
	} else {
		c.logger.Debug("Kind cluster is not running", slog.String("name", c.name))
	}

	return nil
}

func (c *KindClusterProvider) Outputs(ctx context.Context, w io.Writer) error {
	// Kind clusters do not have outputs.
	return nil
}

func (c *KindClusterProvider) KubeConfig(ctx context.Context, w io.Writer, internal bool) error {
	kindProvider := cluster.NewProvider(c.nodeProvider,
		cluster.ProviderWithLogger(&slogAdapter{Logger: c.logger}))

	kubeConfigBytes, err := kindProvider.KubeConfig(c.name, internal)
	if err != nil {
		return fmt.Errorf("failed to get kubeconfig: %w", err)
	}

	if _, err = w.Write([]byte(kubeConfigBytes)); err != nil {
		return fmt.Errorf("failed to write kubeconfig: %w", err)
	}

	return nil
}

func (c *KindClusterProvider) WireGuardConfig(ctx context.Context, w io.Writer) (hasConfig bool, err error) {
	// Kind clusters do not use WireGuard.
	return false, nil
}

func (c *KindClusterProvider) isRunning() (bool, error) {
	kindProvider := cluster.NewProvider(c.nodeProvider,
		cluster.ProviderWithLogger(&slogAdapter{Logger: c.logger}))

	clusters, err := kindProvider.List()
	if err != nil {
		return false, fmt.Errorf("failed to list kind clusters: %w", err)
	}

	for _, cluster := range clusters {
		if cluster == c.name {
			return true, nil
		}
	}

	return false, nil
}

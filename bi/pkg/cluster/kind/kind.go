package kind

import (
	"context"
	"fmt"
	"io"
	"log/slog"

	"sigs.k8s.io/kind/pkg/cluster"
	"sigs.k8s.io/kind/pkg/log"
)

const (
	KindImage = "kindest/node:v1.29.2"
)

type KindClusterProvider struct {
	logger       *slog.Logger
	kindProvider *cluster.Provider
	name         string
}

func NewClusterProvider(logger *slog.Logger, name string) *KindClusterProvider {
	return &KindClusterProvider{
		logger: logger,
		name:   name,
	}
}

func (c *KindClusterProvider) Init(ctx context.Context) error {
	po, err := cluster.DetectNodeProvider()
	if err != nil {
		return fmt.Errorf("failed to detect node provider: %w", err)
	}
	if po == nil {
		return fmt.Errorf("neither docker nor podman are available")
	}

	c.kindProvider = cluster.NewProvider(po, cluster.ProviderWithLogger(log.NoopLogger{}))
	return nil
}

func (c *KindClusterProvider) Create(ctx context.Context) error {
	isRunning, err := c.isRunning()
	if err != nil {
		return err
	}

	if !isRunning {
		co := []cluster.CreateOption{
			// We'll need to configure the cluster here
			// if customers need to access the docker images.
			cluster.CreateWithNodeImage(KindImage),
			cluster.CreateWithDisplayUsage(false),
			cluster.CreateWithDisplaySalutation(false),
		}

		c.logger.Info("Creating kind cluster", slog.String("name", c.name), slog.String("image", KindImage))

		if err := c.kindProvider.Create(c.name, co...); err != nil {
			return err
		}
	} else {
		c.logger.Debug("Kind cluster already running", slog.String("name", c.name))
	}

	return nil
}

func (c *KindClusterProvider) Destroy(ctx context.Context) error {
	isRunning, err := c.isRunning()
	if err != nil {
		return err
	}

	if isRunning {
		c.logger.Info("Deleting kind cluster", slog.String("name", c.name))
		if err := c.kindProvider.Delete(c.name, ""); err != nil {
			return err
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
	kubeConfigBytes, err := c.kindProvider.KubeConfig(c.name, internal)
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
	clusters, err := c.kindProvider.List()
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

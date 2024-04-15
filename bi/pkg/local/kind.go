package local

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"os"
	"path/filepath"

	"github.com/pkg/errors"
	"sigs.k8s.io/kind/pkg/cluster"
	kindLogger "sigs.k8s.io/kind/pkg/log"
)

const (
	KindImage = "kindest/node:v1.29.2"
)

type KindClusterProvider struct {
	kindProvider *cluster.Provider
	name         string
}

var defaultKindClusterName = "bi"

func DefaultKindClusterName() string {
	return defaultKindClusterName
}

func StartDefaultKindCluster() (*KindClusterProvider, error) {
	c, err := NewKindClusterProvider(defaultKindClusterName)
	if err != nil {
		return nil, err
	}

	err = c.EnsureStarted()
	if err != nil {
		return nil, err
	}

	return c, nil
}

func StopDefaultKindCluster() error {
	c, err := NewKindClusterProvider(defaultKindClusterName)
	if err != nil {
		return err
	}

	err = c.EnsureDeleted()
	if err != nil {
		return err
	}
	return nil
}

func NewKindClusterProvider(name string) (*KindClusterProvider, error) {
	po, err := cluster.DetectNodeProvider()
	if err != nil {
		return nil, err
	}
	if po == nil {
		return nil, errors.New("kind could not detect docker or podman; install docker")
	}
	p := cluster.NewProvider(po, cluster.ProviderWithLogger(kindLogger.NoopLogger{}))
	c := &KindClusterProvider{kindProvider: p, name: name}
	return c, nil
}

// EnsureStarted  takes in a KindLocalCluster and the
// kind_provider from uses kubernetes-sigs/kind/blob/main/pkg/cluster to
// list the clusters, see if
// cluster is running, and then create the cluster
// if missing
func (c *KindClusterProvider) EnsureStarted() error {
	clusters, err := c.kindProvider.List()
	if err != nil {
		return err
	}

	slog.Debug("Found running kind clusters: ", "cluster_list", clusters)
	for _, cluster := range clusters {
		if cluster == c.name {
			// cluster is running
			return nil
		}
	}

	// cluster is not running
	co := []cluster.CreateOption{
		// We'll need to configure the cluster here
		// if customers need to access the docker images.
		cluster.CreateWithNodeImage(KindImage),
		cluster.CreateWithDisplayUsage(false),
		cluster.CreateWithDisplaySalutation(false),
	}

	slog.Info("Creating kind cluster", slog.String("name", c.name), slog.String("image", KindImage))
	err = c.kindProvider.Create(c.name, co...)

	if err != nil {
		return err
	}

	return nil
}

func (c *KindClusterProvider) EnsureDeleted() error {
	clusters, err := c.kindProvider.List()
	if err != nil {
		return err
	}

	for _, cluster := range clusters {
		if cluster == c.name {
			slog.Info("Deleting kind cluster", "name", c.name)
			err = c.kindProvider.Delete(c.name, "")
			if err != nil {
				return err
			}
		}
	}

	return nil
}

func (c *KindClusterProvider) KubeConfig(_ context.Context, w io.Writer, internal bool) error {
	// Create a temporary directory for the kubeconfig (as the kind api only supports exporting to file).
	kubeConfigDir, err := os.MkdirTemp("", "kind-kubeconfig")
	if err != nil {
		return fmt.Errorf("failed to create temp kubeconfig directory: %w", err)
	}
	defer os.RemoveAll(kubeConfigDir)

	// Restrict to the current user.
	if err := os.Chmod(kubeConfigDir, 0o700); err != nil {
		return fmt.Errorf("failed to change permissions on temp kubeconfig directory: %w", err)
	}

	// Export the kubeconfig.
	kubeConfigPath := filepath.Join(kubeConfigDir, "kubeconfig")
	if err := c.kindProvider.ExportKubeConfig(c.name, kubeConfigPath, internal); err != nil {
		return fmt.Errorf("failed to export kubeconfig: %w", err)
	}

	// Copy the kubeconfig to the writer.
	kubeConfigFile, err := os.Open(kubeConfigPath)
	if err != nil {
		return fmt.Errorf("failed to open kubeconfig: %w", err)
	}
	defer kubeConfigFile.Close()

	if _, err := io.Copy(w, kubeConfigFile); err != nil {
		return fmt.Errorf("failed to write kubeconfig: %w", err)
	}

	return nil
}

func (c *KindClusterProvider) WireGuardConfig(_ context.Context, _ io.Writer) (bool, error) {
	// Local clusters do not use WireGuard.
	return false, nil
}

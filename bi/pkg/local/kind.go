package local

import (
	"github.com/pkg/errors"
	"sigs.k8s.io/kind/pkg/cluster"
	"sigs.k8s.io/kind/pkg/log"
)

const (
	kindImage = "kindest/node:v1.26.14"
)

type KindClusterProvider struct {
	kindProvider *cluster.Provider
	name         string
}

func NewKindClusterProvider(name string) (*KindClusterProvider, error) {
	po, err := cluster.DetectNodeProvider()
	if err != nil {
		return nil, err
	}
	if po == nil {
		return nil, errors.New("kind could not detect docker or podman; install docker")
	}
	p := cluster.NewProvider(po, cluster.ProviderWithLogger(log.NoopLogger{}))
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
		cluster.CreateWithNodeImage(kindImage),
		cluster.CreateWithDisplayUsage(false),
		cluster.CreateWithDisplaySalutation(false),
	}

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
			err = c.kindProvider.Delete(c.name, "")
			if err != nil {
				return err
			}
		}
	}

	return nil
}

package kind

import (
	"bi/pkg/cluster/kind/localgateway"
	"bi/pkg/cluster/util"
	"bi/pkg/wireguard"
	"context"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/netip"

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
	gwEnabled    bool
	gw           localgateway.Gateway
	wgGateway    *wireguard.Gateway
	wgClient     *wireguard.Client
}

func NewClusterProvider(logger *slog.Logger, name string, gatewayEnabled bool) *KindClusterProvider {
	return &KindClusterProvider{
		logger:    logger,
		name:      name,
		gwEnabled: gatewayEnabled,
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

	if c.gwEnabled {
		// Use the same CIDR block as AWS.
		_, gatewayCIDRBlock, err := net.ParseCIDR("100.64.250.0/24")
		if err != nil {
			return fmt.Errorf("failed to parse gateway CIDR block: %w", err)
		}

		c.wgGateway, err = wireguard.NewGateway(51820, gatewayCIDRBlock)
		if err != nil {
			return fmt.Errorf("failed to create wireguard gateway: %w", err)
		}

		c.wgClient, err = c.wgGateway.NewClient("installer")
		if err != nil {
			return fmt.Errorf("failed to create wireguard client for installer: %w", err)
		}

		if IsDockerAvailable() {
			slog.Debug("Using Docker as the gateway provider")

			c.gw, err = localgateway.NewDockerGateway(c.name, c.wgGateway)
			if err != nil {
				return fmt.Errorf("failed to create docker gateway: %w", err)
			}
		} else if IsPodmanAvailable() {
			slog.Debug("Using Podman as the gateway provider")

			c.gw, err = localgateway.NewPodmanGateway(c.name, c.wgGateway)
			if err != nil {
				return fmt.Errorf("failed to create podman gateway: %w", err)
			}
		} else {
			return fmt.Errorf("neither docker nor podman are available")
		}
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

	// Create the wireguard gateway container.
	if c.gwEnabled {
		if err := c.gw.Create(ctx); err != nil {
			return fmt.Errorf("failed to create wireguard gateway: %w", err)
		}
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

	// Remove the wireguard gateway container (if it exists).
	if c.gwEnabled {
		if err := c.gw.Destroy(ctx); err != nil {
			return fmt.Errorf("failed to remove wireguard gateway: %w", err)
		}
	}

	return nil
}

func (c *KindClusterProvider) Outputs(ctx context.Context, w io.Writer) error {
	// Kind clusters do not have outputs.
	return nil
}

func (c *KindClusterProvider) KubeConfig(ctx context.Context, w io.Writer) error {
	kindProvider := cluster.NewProvider(c.nodeProvider,
		cluster.ProviderWithLogger(&slogAdapter{Logger: c.logger}))

	kubeConfigBytes, err := kindProvider.KubeConfig(c.name, c.gwEnabled)
	if err != nil {
		return fmt.Errorf("failed to get kubeconfig: %w", err)
	}

	if _, err = w.Write([]byte(kubeConfigBytes)); err != nil {
		return fmt.Errorf("failed to write kubeconfig: %w", err)
	}

	return nil
}

func (c *KindClusterProvider) WireGuardConfig(ctx context.Context, w io.Writer) (bool, error) {
	if !c.gwEnabled {
		return false, nil
	}

	gwEndpoint, err := c.gw.Endpoint(ctx)
	if err != nil {
		return true, fmt.Errorf("failed to get wireguard gateway address: %w", err)
	}

	c.wgGateway.Endpoint = gwEndpoint
	c.wgGateway.Nameservers = []netip.Addr{c.wgGateway.Address} // The gateway is hosting a DNS server.

	// Get the CIDR of the `kind` network.
	c.wgGateway.VPCSubnets, err = c.gw.GetNetworks(ctx)
	if err != nil {
		return true, err
	}

	if err := c.wgClient.WriteConfig(w); err != nil {
		return true, fmt.Errorf("error writing wireguard config: %w", err)
	}

	return true, nil
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

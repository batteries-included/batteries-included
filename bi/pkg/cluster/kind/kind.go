package kind

import (
	"bi/pkg/cluster/util"
	"bi/pkg/wireguard"
	"context"
	_ "embed"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/netip"
	"os"
	"time"

	"github.com/avast/retry-go/v4"
	dockerclient "github.com/docker/docker/client"
	slogmulti "github.com/samber/slog-multi"
	"sigs.k8s.io/kind/pkg/apis/config/v1alpha4"
	"sigs.k8s.io/kind/pkg/cluster"
	"sigs.k8s.io/kind/pkg/cluster/nodes"
	"sigs.k8s.io/kind/pkg/cluster/nodeutils"
)

const (
	// This ideally will be a pre-built image for the kind release we're using
	// But should match the minor version of k8s that we're running in AWS
	//
	// Kind only does sha256 in order to attach kind binary version to the OCI image version
	// This means that when we update kind dependency we should get the corresponding image
	// digest from the last kind release
	//
	// https://github.com/kubernetes-sigs/kind/releases/latest
	KindImage         = "kindest/node:v1.33.4@sha256:25a6018e48dfcaee478f4a59af81157a437f15e6e140bf103f85a2e7cd0cbbf2"
	NoisySocketsImage = "ghcr.io/noisysockets/nsh:v0.9.3"
)

type KindClusterProvider struct {
	logger         *slog.Logger
	nodeProvider   cluster.ProviderOption
	name           string
	dockerClient   *dockerclient.Client
	gatewayEnabled bool
	wgGateway      *wireguard.Gateway
	wgClient       *wireguard.Client
	// GPU support fields
	gpuAvailable        bool
	gpuCount            int
	nvidiaAutoDiscovery bool
}

func NewClusterProvider(logger *slog.Logger, name string, gatewayEnabled bool, nvidiaAutoDiscovery bool) *KindClusterProvider {
	return &KindClusterProvider{
		logger:              logger,
		name:                name,
		gatewayEnabled:      gatewayEnabled,
		nvidiaAutoDiscovery: nvidiaAutoDiscovery,
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

	// Create Docker client for both GPU detection and gateway functionality
	c.dockerClient, err = dockerclient.NewClientWithOpts(dockerclient.FromEnv, dockerclient.WithAPIVersionNegotiation())
	if err != nil {
		c.logger.Warn("Failed to create Docker client", slog.String("error", err.Error()))
		// Continue without Docker client - some functionality may be limited
	}

	// Detect GPU support
	if err := c.detectGPUs(ctx); err != nil {
		return fmt.Errorf("failed to detect GPUs: %w", err)
	}

	if c.gatewayEnabled {
		return c.initForGateway()
	}

	return nil
}

func (c *KindClusterProvider) initForGateway() error {
	if c.dockerClient == nil {
		return fmt.Errorf("docker client is required for gateway functionality")
	}

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

	return nil
}

func (c *KindClusterProvider) Create(ctx context.Context, progressReporter *util.ProgressReporter) error {
	isRunning, err := c.isRunning()
	if err != nil {
		return fmt.Errorf("failed to check if kind cluster is running: %w", err)
	}

	logger := c.logger
	if progressReporter != nil {
		logInterceptor := progressReporter.ForKindCreateLogs()
		defer logInterceptor.(io.Closer).Close()

		logger = slog.New(slogmulti.Fanout(
			c.logger.Handler(),
			logInterceptor,
		))
	}

	if !isRunning {
		clusterConfig := c.createClusterConfig()
		createOpts := []cluster.CreateOption{
			// We'll need to configure the cluster here
			// if customers need to access the docker images.
			cluster.CreateWithNodeImage(KindImage),
			cluster.CreateWithDisplayUsage(false),
			cluster.CreateWithDisplaySalutation(false),
			cluster.CreateWithV1Alpha4Config(clusterConfig),
		}

		if c.gpuAvailable {
			c.logger.Info("Creating kind cluster with GPU support",
				slog.Int("gpu_count", c.gpuCount))
		} else {
			c.logger.Info("Creating kind cluster without GPU support")
		}

		kindProvider := c.kindProviderWithLogger(logger)
		// Do the damn thing.
		if err := kindProvider.Create(c.name, createOpts...); err != nil {
			return fmt.Errorf("failed to create kind cluster: %w", err)
		}

		// Setup GPU support on cluster nodes after creation
		if c.gpuAvailable {
			if err := c.setupGPUNodes(ctx, kindProvider, c.name, progressReporter); err != nil {
				return fmt.Errorf("failed to setup GPU support: %w", err)
			}
		}
	} else {
		c.logger.Debug("Kind cluster already running", slog.String("name", c.name))
	}

	if err := c.maybeLoadImages(ctx); err != nil {
		return fmt.Errorf("failed to load images: %w", err)
	}

	// Create the wireguard gateway container.
	if c.gatewayEnabled {
		if err := c.createWireGuardGateway(ctx); err != nil {
			return fmt.Errorf("failed to create wireguard gateway: %w", err)
		}
	}

	return nil
}

// createClusterConfig creates a kind cluster configuration, with GPU support if available
func (c *KindClusterProvider) createClusterConfig() *v1alpha4.Cluster {
	// Create a basic cluster config with control plane node
	config := &v1alpha4.Cluster{
		TypeMeta: v1alpha4.TypeMeta{
			Kind:       "Cluster",
			APIVersion: "kind.x-k8s.io/v1alpha4",
		},
		FeatureGates: map[string]bool{
			"InPlacePodVerticalScaling": true,
		},
		Nodes: []v1alpha4.Node{
			{
				Role: v1alpha4.ControlPlaneRole,
			},
		},
	}

	// Add default mounts to all nodes
	defaultMounts := []v1alpha4.Mount{}

	// Mount the current user's home directory if available
	if homeDir, err := os.UserHomeDir(); err == nil {
		defaultMounts = append(defaultMounts, v1alpha4.Mount{
			HostPath:      homeDir,
			ContainerPath: "/var/host-mounts/home",
		})
	}

	// Add GPU-specific configuration if GPUs are available
	if c.gpuAvailable {
		defaultMounts = append(defaultMounts, v1alpha4.Mount{
			// This is a very specific thing that tells the NVIDIA container runtime
			// which gpus to share with this container.
			//
			// In order for it to work though the user needs to have enabled some
			// settings. We should add checks that inform the user what they need
			// to have enabled.
			HostPath:      "/dev/null",
			ContainerPath: "/var/run/nvidia-container-devices/all",
		})
	}

	// Apply mounts to the control plane node
	if len(defaultMounts) > 0 {
		config.Nodes[0].ExtraMounts = defaultMounts
	}

	return config
}

func (c *KindClusterProvider) Destroy(ctx context.Context, _ *util.ProgressReporter) error {
	isRunning, err := c.isRunning()
	if err != nil {
		return fmt.Errorf("failed to check if kind cluster is running: %w", err)
	}

	if isRunning {
		if err := c.kindProvider().Delete(c.name, ""); err != nil {
			return fmt.Errorf("failed to delete existing kind cluster: %w", err)
		}
	} else {
		c.logger.Debug("Kind cluster is not running", slog.String("name", c.name))
	}

	// Remove the wireguard gateway container (if it exists).
	if c.gatewayEnabled {
		if err := c.destroyWireGuardGateway(ctx); err != nil {
			return fmt.Errorf("failed to remove wireguard gateway: %w", err)
		}
	}

	return nil
}

func (c *KindClusterProvider) WriteOutputs(ctx context.Context, w io.Writer) error {
	// Kind clusters do not have outputs.
	return nil
}

func (c *KindClusterProvider) WriteKubeConfig(ctx context.Context, w io.Writer) error {
	kubeConfigBytes, err := c.kindProvider().KubeConfig(c.name, c.gatewayEnabled)
	if err != nil {
		return fmt.Errorf("failed to get kubeconfig: %w", err)
	}

	if _, err = w.Write([]byte(kubeConfigBytes)); err != nil {
		return fmt.Errorf("failed to write kubeconfig: %w", err)
	}

	return nil
}

func (c *KindClusterProvider) WriteWireGuardConfig(ctx context.Context, w io.Writer) (bool, error) {
	if !c.gatewayEnabled {
		return false, nil
	}

	containerID, err := c.getWireGuardGatewayContainer(ctx)
	if err != nil {
		return true, fmt.Errorf("failed to get wireguard gateway container: %w", err)
	}

	gwEndpoint, err := c.getWireGuardGatewayEndpoint(ctx, containerID)
	if err != nil {
		return true, fmt.Errorf("failed to get wireguard gateway address: %w", err)
	}

	c.wgGateway.Endpoint = gwEndpoint
	c.wgGateway.Nameservers = []netip.Addr{c.wgGateway.Address} // The gateway is hosting a DNS server.

	// Get the CIDR of the `kind` network.
	_, c.wgGateway.VPCSubnets, err = getKindNetworks(ctx)
	if err != nil {
		return true, err
	}

	if err := c.wgClient.WriteConfig(w); err != nil {
		return true, fmt.Errorf("error writing wireguard config: %w", err)
	}

	return true, nil
}

func (c *KindClusterProvider) isRunning() (bool, error) {
	clusters, err := c.kindProvider().List()
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

func (c *KindClusterProvider) maybeLoadImages(ctx context.Context) error {
	imageTarPath := os.Getenv("BI_IMAGE_TAR")
	if imageTarPath == "" {
		return nil
	}
	logger := c.logger.With(slog.String("BI_IMAGE_TAR", imageTarPath))
	logger.Info("Loading images")

	if _, err := os.Stat(imageTarPath); err != nil {
		return err
	}

	nodelist, err := c.kindProvider().ListInternalNodes(c.name)
	if err != nil {
		return err
	}

	for _, node := range nodelist {
		_ = c.loadImages(ctx, imageTarPath, node)
	}
	logger.Info("Finished loading images")

	return nil
}

func (c *KindClusterProvider) kindProvider() *cluster.Provider {
	return c.kindProviderWithLogger(c.logger)
}

func (c *KindClusterProvider) kindProviderWithLogger(logger *slog.Logger) *cluster.Provider {
	return cluster.NewProvider(
		c.nodeProvider,
		cluster.ProviderWithLogger(&slogAdapter{Logger: logger}),
	)
}

// loadImage loads tar image(s) to a node
// borrowed from:
// https://github.com/kubernetes-sigs/kind/blob/07574072a34/pkg/cmd/kind/load/image-archive/image-archive.go#L145C1-L153C2
func (c *KindClusterProvider) loadImages(ctx context.Context, imageTarName string, node nodes.Node) error {
	return retry.Do(func() error {
		c.logger.Debug("loading images to node", slog.String("node", node.String()), slog.String("path", imageTarName))
		f, err := os.Open(imageTarName)
		if err != nil {
			return err
		}
		defer f.Close()
		return nodeutils.LoadImageArchive(node, f)
	},
		retry.Context(ctx),
		retry.MaxDelay(5*time.Second),
	)
}

// HasNvidiaRuntimeInstalled returns true if NVIDIA runtime was installed during cluster creation
func (c *KindClusterProvider) HasNvidiaRuntimeInstalled() bool {
	return c.gpuAvailable
}

// HasGPUs returns true if NVIDIA GPUs are available and detected
func (c *KindClusterProvider) HasGPUs() bool {
	return c.gpuAvailable
}

// GetGPUCount returns the number of detected NVIDIA GPUs
func (c *KindClusterProvider) GetGPUCount() int {
	return c.gpuCount
}

// HasDockerClient returns true if a Docker client is available
func (c *KindClusterProvider) HasDockerClient() bool {
	return c.dockerClient != nil
}

// GetDockerClient returns the Docker client if available
func (c *KindClusterProvider) GetDockerClient() *dockerclient.Client {
	return c.dockerClient
}

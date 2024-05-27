package kube_test

import (
	"bi/pkg/cluster/kind"
	"bi/pkg/kube"
	"bi/pkg/testutil"
	"context"
	"log/slog"
	"net"
	"os"
	"path/filepath"
	"testing"

	dockernetwork "github.com/docker/docker/api/types/network"
	noisysocketsconfig "github.com/noisysockets/noisysockets/config"
	noisysocketsv1alpha2 "github.com/noisysockets/noisysockets/config/v1alpha2"
	noisysocketstypes "github.com/noisysockets/noisysockets/types"
	"github.com/stretchr/testify/require"

	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/network"
)

func TestBatteryKubeClient(t *testing.T) {
	testutil.IntegrationTest(t)

	outputDir := t.TempDir()

	ctx := context.Background()

	// Create an IPAM configuration for the private network.
	ipamConfig := dockernetwork.IPAM{
		Driver: "default",
		Config: []dockernetwork.IPAMConfig{
			{
				Subnet:  "10.1.1.0/24",
				Gateway: "10.1.1.254",
			},
		},
		Options: map[string]string{
			"driver": "host-local",
		},
	}

	// Create a private network, it'll be assigned a unique CIDR.
	testNetwork, err := network.New(ctx, network.WithCheckDuplicate(), network.WithIPAM(&ipamConfig))
	require.NoError(t, err)
	t.Cleanup(func() {
		require.NoError(t, testNetwork.Remove(ctx))
	})

	// Generate a keypair for the gateway and client.
	gwPrivateKey, err := noisysocketstypes.NewPrivateKey()
	require.NoError(t, err)

	clientPrivateKey, err := noisysocketstypes.NewPrivateKey()
	require.NoError(t, err)

	gwConf := &noisysocketsv1alpha2.Config{
		ListenPort: 51820,
		PrivateKey: gwPrivateKey.String(),
		IPs:        []string{"100.64.0.1"},
		Peers: []noisysocketsv1alpha2.PeerConfig{
			{
				PublicKey: clientPrivateKey.Public().String(),
				IPs:       []string{"100.64.0.2"},
			},
		},
	}

	// Marshall and write out the gateway configuration.
	gwConfPath := filepath.Join(outputDir, "gateway.yaml")
	gwConfFile, err := os.OpenFile(gwConfPath, os.O_CREATE|os.O_WRONLY, 0o400)
	require.NoError(t, err)
	require.NoError(t, noisysocketsconfig.ToYAML(gwConfFile, gwConf))
	require.NoError(t, gwConfFile.Close())

	// Spin up a wireguard gateway server using the userspace router implementation.
	// This gateway will forward traffic to the private test network.
	wgReq := testcontainers.ContainerRequest{
		Image:        "ghcr.io/noisysockets/nsh:v0.5.1",
		ExposedPorts: []string{"51820/udp"},
		Cmd: []string{"serve",
			"--config=/etc/nsh/noisysockets.yaml",
			"--enable-dns", "--enable-router",
		},
		Files: []testcontainers.ContainerFile{
			// Normally this would be 0o400 but testcontainers doesn't let us set the
			// file owner.
			{HostFilePath: gwConfPath, ContainerFilePath: "/etc/nsh/noisysockets.yaml", FileMode: 0o444},
		},
		Networks: []string{testNetwork.Name},
	}

	wgC, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: wgReq,
		Started:          true,
	})
	require.NoError(t, err)
	t.Cleanup(func() {
		require.NoError(t, wgC.Terminate(ctx))
	})

	// Store the host and port of the wireguard server (so it can be added to the client config).
	wgHost, err := wgC.Host(ctx)
	require.NoError(t, err)

	wgAddrs, err := net.LookupHost(wgHost)
	require.NoError(t, err)

	wgPort, err := wgC.MappedPort(ctx, "51820/udp")
	require.NoError(t, err)

	// Create a kind cluster using the private network.
	os.Setenv("KIND_EXPERIMENTAL_DOCKER_NETWORK", testNetwork.Name)

	t.Log("Creating kind cluster")
	clusterProvider := kind.NewClusterProvider(slog.Default(), "bi-wg-test")
	require.NoError(t, err)

	require.NoError(t, clusterProvider.Init(ctx))
	require.NoError(t, clusterProvider.Create(ctx))

	t.Cleanup(func() {
		t.Log("Deleting kind cluster")

		require.NoError(t, os.Unsetenv("KIND_EXPERIMENTAL_DOCKER_NETWORK"))

		require.NoError(t, clusterProvider.Destroy(ctx))
	})

	// Get a kubeconfig for the kind cluster (using its internal domain name).
	kubeConfigPath := filepath.Join(outputDir, "kubeconfig")

	kubeConfigFile, err := os.Create(kubeConfigPath)
	require.NoError(t, err)

	require.NoError(t, clusterProvider.KubeConfig(ctx, kubeConfigFile, true))
	require.NoError(t, kubeConfigFile.Close())

	// Create a WireGuard client configuration.
	clientConf := &noisysocketsv1alpha2.Config{
		Name:       "test-client",
		PrivateKey: clientPrivateKey.String(),
		IPs:        []string{"100.64.0.2"},
		DNS: &noisysocketsv1alpha2.DNSConfig{
			Servers: []string{"100.64.0.1"},
		},
		Routes: []noisysocketsv1alpha2.RouteConfig{
			{
				Destination: ipamConfig.Config[0].Subnet,
				Via:         "gateway",
			},
		},
		Peers: []noisysocketsv1alpha2.PeerConfig{
			{
				Name:      "gateway",
				PublicKey: gwPrivateKey.Public().String(),
				IPs:       []string{"100.64.0.1"},
				Endpoint:  net.JoinHostPort(wgAddrs[0], wgPort.Port()),
			},
		},
	}

	clientConfPath := filepath.Join(outputDir, "client.yaml")
	clientConfFile, err := os.OpenFile(clientConfPath, os.O_CREATE|os.O_WRONLY, 0o400)
	require.NoError(t, err)
	require.NoError(t, noisysocketsconfig.ToYAML(clientConfFile, clientConf))
	require.NoError(t, clientConfFile.Close())

	// Create a new kubernetes client that will send all requests over WireGuard.
	kubeClient, err := kube.NewBatteryKubeClient(kubeConfigPath, clientConfPath)
	require.NoError(t, err)
	t.Cleanup(func() {
		require.NoError(t, kubeClient.Close())
	})

	t.Run("EnsureResourceExists", func(t *testing.T) {
		err = kubeClient.EnsureResourceExists(ctx, map[string]any{
			"apiVersion": "v1",
			"kind":       "Namespace",
			"metadata": map[string]any{
				"name": "test-namespace",
			},
		})
		require.NoError(t, err)
	})
}

package kube_test

import (
	"context"
	"net"
	"net/netip"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"bi/pkg/kube"
	"bi/pkg/local"
	"bi/pkg/testutil"
	"bi/pkg/wireguard"

	"github.com/docker/docker/api/types/container"
	"github.com/stretchr/testify/require"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/network"
	"github.com/testcontainers/testcontainers-go/wait"
)

func TestBatteryKubeClient(t *testing.T) {
	testutil.IntegrationTest(t)

	ctx := context.Background()

	// Create a private network, it'll be assigned a unique CIDR.
	testNetwork, err := network.New(ctx, network.WithCheckDuplicate())
	require.NoError(t, err)
	t.Cleanup(func() {
		require.NoError(t, testNetwork.Remove(ctx))
	})

	// Write out a wireguard config for the test
	_, subnet, err := net.ParseCIDR("10.7.0.0/24")
	require.NoError(t, err)

	gw, err := wireguard.NewGateway(51820, subnet)
	require.NoError(t, err)

	gw.DNSServers = []netip.Addr{netip.MustParseAddr("10.7.0.1")}
	gw.PostUp = []string{
		"iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE",
	}
	gw.PreDown = []string{
		"iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE",
	}

	installerClient, err := gw.NewClient("installer")
	require.NoError(t, err)

	var sb strings.Builder
	require.NoError(t, gw.WriteConfig(&sb))

	outputDir := t.TempDir()

	// Write out the wireguard config to a file.
	require.NoError(t, os.WriteFile(filepath.Join(outputDir, "wg0.conf"), []byte(sb.String()), 0o400))

	// Spin up a wireguard gateway server using the userspace wireguard-go implementation.
	// This gateway will forward traffic to the private test network.
	wgReq := testcontainers.ContainerRequest{
		Image:        "ghcr.io/noisysockets/gateway:v0.1.0",
		ExposedPorts: []string{"51820/udp", "53/tcp"},
		Files: []testcontainers.ContainerFile{
			{HostFilePath: filepath.Join(outputDir, "wg0.conf"), ContainerFilePath: "/etc/wireguard/wg0.conf", FileMode: 0o400},
		},
		Networks: []string{testNetwork.Name},
		HostConfigModifier: func(hostConfig *container.HostConfig) {
			hostConfig.CapAdd = []string{"NET_ADMIN"}

			hostConfig.Sysctls = map[string]string{
				"net.ipv4.ip_forward":              "1",
				"net.ipv4.conf.all.src_valid_mark": "1",
			}

			hostConfig.Binds = append(hostConfig.Binds, "/dev/net/tun:/dev/net/tun")
		},
		// Rely on the fact dnsmasq is started after the interface is up.
		WaitingFor: wait.ForListeningPort("53/tcp"),
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

	gw.Endpoint = netip.AddrPortFrom(netip.MustParseAddr(wgAddrs[0]), uint16(wgPort.Int()))

	// Create a kind cluster using the private network.
	os.Setenv("KIND_EXPERIMENTAL_DOCKER_NETWORK", testNetwork.Name)

	t.Log("Creating kind cluster")
	clusterProvider, err := local.NewKindClusterProvider("bi-wg-test")
	require.NoError(t, err)

	require.NoError(t, clusterProvider.EnsureStarted())

	t.Cleanup(func() {
		t.Log("Deleting kind cluster")

		require.NoError(t, os.Unsetenv("KIND_EXPERIMENTAL_DOCKER_NETWORK"))

		require.NoError(t, clusterProvider.EnsureDeleted())
	})

	// Get a kubeconfig for the kind cluster (using its internal domain name).
	kubeConfigPath := filepath.Join(outputDir, "kubeconfig")
	require.NoError(t, clusterProvider.ExportKubeConfig(kubeConfigPath))

	// Create a WireGuard client configuration.
	sb = strings.Builder{}
	require.NoError(t, installerClient.WriteConfig(&sb))

	wireGuardConfigPath := filepath.Join(outputDir, "wireguard.yaml")
	require.NoError(t, os.WriteFile(wireGuardConfigPath, []byte(sb.String()), 0o400))

	// Create a new kubernetes client that will send all requests over WireGuard.
	kubeClient, err := kube.NewBatteryKubeClient(kubeConfigPath, wireGuardConfigPath)
	require.NoError(t, err)
	t.Cleanup(func() {
		require.NoError(t, kubeClient.Close())
	})

	t.Run("EnsureResourceExists", func(t *testing.T) {
		err = kubeClient.EnsureResourceExists(map[string]any{
			"apiVersion": "v1",
			"kind":       "Namespace",
			"metadata": map[string]any{
				"name": "test-namespace",
			},
		})
		require.NoError(t, err)
	})
}

package kube_test

import (
	"bi/pkg/kube"
	"bi/pkg/local"
	"bi/pkg/testutil"
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"text/template"
	"time"

	"github.com/docker/docker/api/types/container"
	"github.com/stretchr/testify/require"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/network"
	"github.com/testcontainers/testcontainers-go/wait"
	"sigs.k8s.io/kind/pkg/cluster"
)

func TestBatteryKubeClient(t *testing.T) {
	testutil.IntegrationTest(t)

	pwd, err := os.Getwd()
	require.NoError(t, err)

	ctx := context.Background()

	// Create a private network, it'll be assigned a unique CIDR.
	testNetwork, err := network.New(ctx, network.WithCheckDuplicate())
	require.NoError(t, err)
	t.Cleanup(func() {
		require.NoError(t, testNetwork.Remove(ctx))
	})

	// Spin up a wireguard gateway server using the userspace wireguard-go implementation.
	// This gateway will forward traffic to the private test network.
	wgReq := testcontainers.ContainerRequest{
		Image:        "ghcr.io/noisysockets/gateway:v0.1.0",
		ExposedPorts: []string{"51820/udp", "53/tcp"},
		Files: []testcontainers.ContainerFile{
			{HostFilePath: filepath.Join(pwd, "testdata/wg0.conf"), ContainerFilePath: "/etc/wireguard/wg0.conf", FileMode: 0o400},
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

	// Create a kind cluster using the private network.
	os.Setenv("KIND_EXPERIMENTAL_DOCKER_NETWORK", testNetwork.Name)

	po, err := cluster.DetectNodeProvider()
	require.NoError(t, err)

	p := cluster.NewProvider(po)

	t.Log("Creating kind cluster")

	clusterName := fmt.Sprintf("kube-test-%d", time.Now().Unix())
	require.NoError(t, p.Create(
		clusterName,
		cluster.CreateWithNodeImage(local.KindImage),
	))
	t.Cleanup(func() {
		t.Log("Deleting kind cluster")

		require.NoError(t, p.Delete(clusterName, ""))
	})

	outputDir := t.TempDir()

	// Get a kubeconfig for the kind cluster (using its internal domain name).
	kubeConfigPath := filepath.Join(outputDir, "kubeconfig")
	require.NoError(t, p.ExportKubeConfig(clusterName, kubeConfigPath, true))

	// Create a WireGuard client configuration.
	wireGuardConfigPath := filepath.Join(outputDir, "wireguard.yaml")
	require.NoError(t, generateConfig(ctx, wireGuardConfigPath, wgC))

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

func generateConfig(ctx context.Context, configPath string, wgC testcontainers.Container) error {
	wgHost, err := wgC.Host(ctx)
	if err != nil {
		return err
	}

	wgPort, err := wgC.MappedPort(ctx, "51820/udp")
	if err != nil {
		return err
	}

	var renderedConfig strings.Builder
	tmpl := template.Must(template.ParseFiles("testdata/wireguard.yaml.tmpl"))
	if err := tmpl.Execute(&renderedConfig, struct {
		Endpoint string
	}{
		Endpoint: wgHost + ":" + wgPort.Port(),
	}); err != nil {
		return err
	}

	return os.WriteFile(configPath, []byte(renderedConfig.String()), 0o400)
}

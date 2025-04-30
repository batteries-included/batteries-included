package kind_test

import (
	"bi/pkg/cluster/kind"
	"bi/pkg/kube"
	"bi/pkg/testutil"
	"context"
	"os"
	"path/filepath"
	"testing"

	"github.com/neilotoole/slogt"
	"github.com/stretchr/testify/require"
)

func TestKindClusterProvider(t *testing.T) {
	testutil.IntegrationTest(t)

	t.Log("Creating kind cluster")
	clusterProvider := kind.NewClusterProvider(slogt.New(t), "bi-test", true)

	ctx := context.Background()
	require.NoError(t, clusterProvider.Init(ctx))
	require.NoError(t, clusterProvider.Create(ctx, nil))

	t.Cleanup(func() {
		t.Log("Deleting kind cluster")

		require.NoError(t, clusterProvider.Destroy(ctx, nil))
	})

	outputDir := t.TempDir()

	// Get a kubeconfig for the kind cluster (using its internal domain name).
	kubeConfigPath := filepath.Join(outputDir, "kubeconfig")

	kubeConfigFile, err := os.Create(kubeConfigPath)
	require.NoError(t, err)

	require.NoError(t, clusterProvider.WriteKubeConfig(ctx, kubeConfigFile))
	require.NoError(t, kubeConfigFile.Close())

	clientConfPath := filepath.Join(outputDir, "client.yaml")
	clientConfFile, err := os.OpenFile(clientConfPath, os.O_CREATE|os.O_WRONLY, 0o400)
	require.NoError(t, err)

	_, err = clusterProvider.WriteWireGuardConfig(ctx, clientConfFile)
	require.NoError(t, err)

	require.NoError(t, clientConfFile.Close())

	// Create a new kubernetes client that will send all requests over WireGuard.
	kubeClient, err := kube.NewBatteryKubeClient(kubeConfigPath, clientConfPath)
	require.NoError(t, err)
	t.Cleanup(func() {
		require.NoError(t, kubeClient.Close())
	})

	// Make sure we can communicate with the Kube API.
	err = kubeClient.EnsureResourceExists(ctx, map[string]any{
		"apiVersion": "v1",
		"kind":       "Namespace",
		"metadata": map[string]any{
			"name": "test-namespace",
		},
	})
	require.NoError(t, err)
}

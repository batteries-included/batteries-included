package specs

import (
	"bi/pkg/kube"
	"context"
	"fmt"
	"log/slog"
)

func (spec *InstallSpec) PrintAccessInfo(ctx context.Context, kubeClient kube.KubeClient) error {
	// Print the control server URL
	// This should only be called after `WaitForBootstrap`
	inCluster, err := spec.GetBatteryConfigField("battery_core", "server_in_cluster")
	if err != nil {
		return fmt.Errorf("failed to determine if control server is running in cluster: %w", err)
	}

	// If we're running in dev mode then assume the control server will be run via `bix dev`
	if !inCluster.(bool) {
		slog.Debug("Control server is not running in cluster")
		return nil
	}

	ns, err := spec.GetCoreNamespace()
	if err != nil {
		return fmt.Errorf("failed to get core namespace: %w", err)
	}

	// Get the access info from kubernetes.
	// It should be stored in a ConfigMap named "access-info"
	// and should be there only after the control server
	// has been bootstrapped.
	accessSpec, err := kubeClient.GetAccessInfo(ctx, ns)

	if err != nil {
		return fmt.Errorf("failed to get access info: %w", err)
	}

	return accessSpec.PrintToConsole()
}

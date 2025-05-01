package specs

import (
	"bi/pkg/cluster/kind"
	"bi/pkg/kube"
	"context"
	"fmt"
	"log/slog"
)

func (spec *InstallSpec) PrintAccessInfo(ctx context.Context, kubeClient kube.KubeClient, slug string) error {
	// Print the control server URL
	// This should only be called after `WaitForBootstrap`
	usage, err := spec.GetCoreUsage()
	if err != nil {
		return fmt.Errorf("failed to determine if control server is running in cluster: %w", err)
	}

	// If we're running in dev mode then assume the control server will be run via `bix dev`
	if usage == "internal_dev" {
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

	if err := accessSpec.PrintToConsole(); err != nil {
		return fmt.Errorf("failed to print access info: %w", err)
	}

	needsLocalGateway, err := spec.NeedsLocalGateway()
	if err != nil {
		return fmt.Errorf("failed to determine if local gateway is needed: %w", err)
	}

	if !needsLocalGateway {
		return nil
	}

	dockerDesktop, err := kind.IsDockerDesktop(ctx)
	if err != nil {
		return err
	}

	podman, _ := kind.IsPodmanAvailable()

	if dockerDesktop || podman {
		fmt.Printf(
			`Because you are using Docker Desktop, to access services running inside the
cluster, you will need to use a Wireguard VPN. To obtain the VPN configuration, 
run the following command:
bi vpn config -o wg0.conf %s
`, slug)
	}

	return nil
}

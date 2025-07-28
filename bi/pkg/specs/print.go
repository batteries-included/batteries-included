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

	// Use improved container runtime detection
	runtimeInfo, err := kind.DetectContainerRuntime(ctx)
	if err != nil {
		slog.Warn("Failed to detect container runtime", slog.String("error", err.Error()))
		runtimeInfo = &kind.ContainerRuntimeInfo{Runtime: kind.RuntimeUnknown}
	}

	if kind.SupportsGateway(runtimeInfo.Runtime) {
		runtimeName := runtimeInfo.Runtime.String()
		if runtimeName == "Unknown" {
			runtimeName = "your container runtime"
		}
		
		configPath := fmt.Sprintf("wg0-%s.conf", slug)
		
		fmt.Printf(
			`Because you are using %s, to access services running inside the
cluster, you will need to use a Wireguard VPN. To obtain the VPN configuration, 
run the following command:

bi vpn config -o %s %s

`, runtimeName, configPath, slug)

		// Provide simplified connection instructions
		fmt.Printf(`To connect to the VPN:
1. Install WireGuard: brew install wireguard-tools
2. Connect: sudo wg-quick up %s
3. Access cluster services in your browser
4. Disconnect: sudo wg-quick down %s

`, configPath, configPath)
		
		fmt.Printf(`For troubleshooting %s specific issues, run:
bi debug runtime-info

`, runtimeInfo.Runtime.String())
	}

	return nil
}

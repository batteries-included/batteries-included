package start

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"bi/pkg/installs"
)

func StartInstall(ctx context.Context, env *installs.InstallEnv) error {
	slog.Info("Starting provider")
	if err := env.StartKubeProvider(ctx); err != nil {
		return fmt.Errorf("unable to start kube provider: %w", err)
	}

	slog.Info("Connecting to cluster")
	kubeClient, err := env.NewBatteryKubeClient()
	if err != nil {
		return fmt.Errorf("unable to create kube client: %w", err)
	}
	defer kubeClient.Close()

	if err := kubeClient.WaitForConnection(3 * time.Minute); err != nil {
		return fmt.Errorf("cluster did not become ready: %w", err)
	}

	slog.Info("Starting initial sync")
	if err := env.Spec.InitialSync(ctx, kubeClient); err != nil {
		return fmt.Errorf("unable to perform initial sync: %w", err)
	}

	slog.Info("Writing state summary to cluster")
	if err := env.Spec.WriteSummaryToKube(ctx, kubeClient); err != nil {
		return fmt.Errorf("unable to write state summary to cluster: %w", err)
	}

	slog.Info("Waiting for bootstrap completion")
	if err := env.Spec.WaitForBootstrap(ctx, kubeClient); err != nil {
		return fmt.Errorf("failed to wait for bootstrap: %w", err)
	}

	slog.Info("Displaying access information")
	if err := env.Spec.PrintAccessInfo(ctx, kubeClient); err != nil {
		return fmt.Errorf("failed get and display access info: %w", err)
	}

	return nil
}

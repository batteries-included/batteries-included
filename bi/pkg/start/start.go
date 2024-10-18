package start

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"bi/pkg/cluster/util"
	"bi/pkg/installs"
	"bi/pkg/log"
)

func StartInstall(ctx context.Context, env *installs.InstallEnv) error {
	slog.Info("Starting provider")

	var progressReporter *util.ProgressReporter
	if log.Level != slog.LevelDebug {
		progressReporter = util.NewProgressReporter()
		defer progressReporter.Shutdown()
	}

	if err := env.StartKubeProvider(ctx, progressReporter); err != nil {
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

	time.Sleep(10 * time.Second)

	slog.Info("Double checking bootstrap completion")
	if err := env.Spec.WaitForBootstrap(ctx, kubeClient); err != nil {
		return fmt.Errorf("failed to wait for bootstrap: %w", err)
	}

	// Explicitly shutdown the progress reporter here to ensure it's not
	// running when we print the access information. That sometimes causes
	// in the progress bar being printed over the access information.
	if progressReporter != nil {
		progressReporter.Shutdown()
	}

	slog.Info("Displaying access information")
	if err := env.Spec.PrintAccessInfo(ctx, kubeClient, env.Slug); err != nil {
		return fmt.Errorf("failed get and display access info: %w", err)
	}

	return nil
}

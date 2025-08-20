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

func StartInstall(ctx context.Context, env *installs.InstallEnv, skipBootstrap bool) error {
	printStartinInfo(env)

	var progressReporter *util.ProgressReporter
	if log.Level == slog.LevelWarn {
		progressReporter = util.NewProgressReporter()
		defer progressReporter.Shutdown()
	}

	if err := env.StartKubeProvider(ctx, progressReporter); err != nil {
		return fmt.Errorf("unable to start kube provider: %w", err)
	}

	if skipBootstrap {
		slog.Info("Skipping bootstrap")
		return nil
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
	if err := env.Spec.InitialSync(ctx, kubeClient, progressReporter); err != nil {
		return fmt.Errorf("unable to perform initial sync: %w", err)
	}

	slog.Info("Writing state summary to cluster")
	if err := env.Spec.WriteSummaryToKube(ctx, kubeClient); err != nil {
		return fmt.Errorf("unable to write state summary to cluster: %w", err)
	}

	slog.Info("Waiting for bootstrap completion")
	if err := env.Spec.WaitForBootstrap(ctx, kubeClient, progressReporter); err != nil {
		return fmt.Errorf("failed to wait for bootstrap: %w", err)
	}

	time.Sleep(10 * time.Second)

	slog.Info("Double checking bootstrap completion")
	if err := env.Spec.WaitForBootstrap(ctx, kubeClient, progressReporter); err != nil {
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

func printStartinInfo(env *installs.InstallEnv) {
	provider := env.Spec.KubeCluster.Provider
	installName := env.Slug

	var timeRange string
	switch provider {
	case "kind":
		timeRange = "30 seconds to 8 minutes"
	case "aws":
		timeRange = "25 minutes to 45 minutes"
	case "provided":
		timeRange = "30 seconds to 5 minutes"
	default:
		timeRange = "unknown"
	}

	slog.Info("Starting install",
		slog.String("name", installName),
		slog.String("provider", provider),
		slog.String("expected_time", timeRange))

	if log.Level == slog.LevelWarn {
		// Print the information
		fmt.Printf("Starting installation %s with expected_time=%s\n", installName, timeRange)
	}
}

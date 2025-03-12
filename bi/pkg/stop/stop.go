package stop

import (
	"context"
	"fmt"
	"log/slog"

	"bi/pkg/cluster/util"
	"bi/pkg/installs"
	"bi/pkg/log"
)

func StopInstall(ctx context.Context, env *installs.InstallEnv, skipCleanKube bool) error {
	slog.Info("Stopping kube provider")

	var progressReporter *util.ProgressReporter
	if log.Level != slog.LevelDebug {
		progressReporter = util.NewProgressReporter()
		defer progressReporter.Shutdown()
	}

	if err := maybeCleanKube(ctx, env, skipCleanKube); err != nil {
		return fmt.Errorf("unable to clean up kubernetes resources: %w", err)
	}

	if err := env.StopKubeProvider(ctx, progressReporter); err != nil {
		return fmt.Errorf("unable to stop kube provider: %w", err)
	}

	slog.Info("Removing install and all keys")
	if err := env.Remove(); err != nil {
		return fmt.Errorf("unable to remove install: %w", err)
	}

	return nil
}

// maybeCleanKube conditionally deletes all k8s resources if the env needs cleanup and we're not skipping
// will close the client before returning to prevent wireguard log spam
func maybeCleanKube(ctx context.Context, env *installs.InstallEnv, skip bool) error {
	needsCleanup := env.NeedsKubeCleanup()

	if skip || !needsCleanup {
		slog.Debug("Skipping kube cleanup", slog.Bool("skip", skip), slog.Bool("envNeedsCleanup", env.NeedsKubeCleanup()))
		return nil
	}

	kubeClient, err := env.NewBatteryKubeClient()
	if err != nil {
		return err
	}
	defer kubeClient.Close()

	return kubeClient.RemoveAll(ctx)
}

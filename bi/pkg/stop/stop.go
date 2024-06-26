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

	if !skipCleanKube {
		kubeClient, err := env.NewBatteryKubeClient()
		if err != nil {
			return err
		}
		defer kubeClient.Close()

		if err := kubeClient.RemoveAll(ctx); err != nil {
			return err
		}
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

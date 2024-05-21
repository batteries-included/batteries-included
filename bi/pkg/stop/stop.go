package stop

import (
	"context"
	"fmt"
	"log/slog"

	"bi/pkg/installs"
)

func StopInstall(ctx context.Context, env *installs.InstallEnv) error {
	slog.Info("Stopping kube provider")
	if err := env.StopKubeProvider(ctx); err != nil {
		return fmt.Errorf("unable to stop kube provider: %w", err)
	}

	slog.Info("Removing install and all keys")
	if err := env.Remove(); err != nil {
		return fmt.Errorf("unable to remove install: %w", err)
	}

	return nil
}

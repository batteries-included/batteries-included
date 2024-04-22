package stop

import (
	"context"
	"fmt"
	"log/slog"

	"bi/pkg/installs"
)

func StopInstall(ctx context.Context, url string) error {
	// Get the install spec
	env, err := installs.NewEnv(ctx, url)
	if err != nil {
		return fmt.Errorf("unable to create install env: %w", err)
	}

	slog.Debug("Stopping kube provider")
	if err := env.StopKubeProvider(ctx); err != nil {
		return fmt.Errorf("unable to stop kube provider: %w", err)
	}

	slog.Debug("Removing install and all keys")
	if err := env.Remove(); err != nil {
		return fmt.Errorf("unable to remove install: %w", err)
	}

	return nil
}

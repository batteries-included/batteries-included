package start

import (
	"context"
	"log/slog"
	"time"

	"bi/pkg/installs"
)

func StartInstall(ctx context.Context, url string) error {
	// Get the install spec
	slog.Debug("fetching install spec", slog.String("url", url))
	env, err := installs.NewEnv(ctx, url)
	if err != nil {
		return err
	}

	slog.Debug("starting provider")
	err = env.StartKubeProvider(ctx)
	if err != nil {
		return err
	}

	kubeClient, err := env.NewBatteryKubeClient()
	if err != nil {
		return err
	}
	defer kubeClient.Close()

	if err := kubeClient.WaitForConnection(3 * time.Minute); err != nil {
		return err
	}

	slog.Debug("starting initial sync")
	err = env.Spec.InitialSync(ctx, kubeClient)
	if err != nil {
		return err
	}

	slog.Debug("writing state summary to cluster")
	err = env.Spec.WriteSummaryToKube(ctx, kubeClient)
	if err != nil {
		return err
	}

	return nil
}

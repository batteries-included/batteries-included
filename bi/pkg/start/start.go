package start

import (
	"context"
	"log/slog"

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

	slog.Debug("starting initial sync")
	err = env.Spec.InitialSync(kubeClient)
	if err != nil {
		return err
	}

	slog.Debug("writing state summary to cluster")
	err = env.Spec.WriteSummaryToKube(kubeClient)
	if err != nil {
		return err
	}

	return nil
}

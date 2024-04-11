package start

import (
	"log/slog"

	"bi/pkg/installs"
	"bi/pkg/kube"
)

func StartInstall(url, kubeConfigPath, wireGuardConfigPath string) error {
	// Get the install spec
	slog.Debug("fetching install spec", slog.String("url", url))
	env, err := installs.NewEnv(url)
	if err != nil {
		return err
	}

	slog.Debug("starting provider")
	err = env.StartKubeProvider()
	if err != nil {
		return err
	}

	kubeClient, err := kube.NewBatteryKubeClient(kubeConfigPath, wireGuardConfigPath)
	if err != nil {
		return err
	}
	defer kubeClient.Close()

	slog.Debug("starting initial sync")
	err = env.Spec.InitialSync(kubeClient)
	if err != nil {
		return err
	}

	return nil
}

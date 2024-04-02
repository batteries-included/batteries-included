package start

import (
	"bi/pkg/kube"
	"bi/pkg/specs"
	"log/slog"
)

func StartInstall(url, kubeConfigPath, wireGuardConfigPath, writeStateSummaryPath string) error {
	// Get the install spec
	slog.Debug("fetching install spec", slog.String("url", url))
	spec, err := specs.GetSpecFromURL(url)
	if err != nil {
		return err
	}

	slog.Debug("starting provider")
	err = spec.StartKubeProvider()
	if err != nil {
		return err
	}

	kubeClient, err := kube.NewBatteryKubeClient(kubeConfigPath, wireGuardConfigPath)
	if err != nil {
		return err
	}
	defer kubeClient.Close()

	slog.Debug("starting initial sync")
	err = spec.InitialSync(kubeClient)
	if err != nil {
		return err
	}

	if writeStateSummaryPath != "" {
		slog.Debug("writing state summary", slog.String("path", writeStateSummaryPath))
		err = spec.WriteStateSummary(writeStateSummaryPath)
		if err != nil {
			return err
		}
	}
	return nil
}

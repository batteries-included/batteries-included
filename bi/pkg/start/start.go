package start

import (
	"bi/pkg/kube"
	"bi/pkg/specs"
)

func StartInstall(url string, kubeConfigPath string, writeStateSummaryPath string) error {
	// Get the install spec
	spec, err := specs.GetSpecFromURL(url)
	if err != nil {
		return err
	}

	err = spec.StartKubeProvider()
	if err != nil {
		return err
	}

	kubeClient, err := kube.NewBatteryKubeClient(kubeConfigPath)
	if err != nil {
		return nil
	}

	err = spec.InitialSync(kubeClient)
	if err != nil {
		return err
	}

	if writeStateSummaryPath != "" {
		err = spec.WriteStateSummary(writeStateSummaryPath)
		if err != nil {
			return err
		}
	}
	return nil
}

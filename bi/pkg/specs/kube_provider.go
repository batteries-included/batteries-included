package specs

import (
	"log/slog"

	"bi/pkg/local"
)

func (spec *InstallSpec) StartKubeProvider() error {
	var err error

	switch spec.KubeCluster.Provider {
	case "kind":
		err = startLocal()
	case "aws":
		err = startAws()
	}

	if err != nil {
		return err
	}
	return nil
}

func (spec *InstallSpec) StopKubeProvider() error {
	var err error

	switch spec.KubeCluster.Provider {
	case "kind":
		err = stopLocal()
	case "aws":
	}

	if err != nil {
		return err
	}
	return nil
}

func startLocal() error {
	slog.Debug("Trying to start kind cluster (unless already running)")
	_, err := local.StartDefaultKindCluster()
	if err != nil {
		return err
	}
	return nil
}

func stopLocal() error {
	slog.Debug("Stopping kind cluster")
	err := local.StopDefaultKindCluster()
	if err != nil {
		return err
	}
	return nil
}

func startAws() error {
	slog.Debug("Starting aws cluster")
	// TODO: Hook this up with pulumi that Jason wrote
	return nil
}

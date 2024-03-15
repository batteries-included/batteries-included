package start

import (
	"bi/pkg/local"
	"bi/pkg/specs"
	"log/slog"
)

func StartInstall(url string) error {
	// Get the install spec
	spec, err := specs.GetSpecFromURL(url)
	if err != nil {
		return err
	}

	if spec.KubeCluster.Provider == "kind" {
		err := startLocal()
		if err != nil {
			return err
		}
	} else if spec.KubeCluster.Provider == "aws" {
		err := startAws()
		if err != nil {
			return err
		}
	}
	return nil
}

func startLocal() error {
	slog.Debug("Starting kind cluster")
	_, err := local.StartDefaultKindCluster()
	if err != nil {
		return err
	}
	return nil
}

func startAws() error {
	slog.Debug("Starting aws cluster")
	return nil
}

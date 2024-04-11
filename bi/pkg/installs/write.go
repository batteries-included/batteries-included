package installs

import (
	"log/slog"
	"os"
)

func (env *InstallEnv) WriteAll() error {
	err := env.WriteSpec(true)
	if err != nil {
		return err
	}
	err = env.WriteSummary(true)
	if err != nil {
		return err
	}

	err = env.WriteKubeConfig(true)
	if err != nil {
		return err
	}

	return nil
}

func (env *InstallEnv) Remove() error {
	// Remove all files in the install directory
	installHome := env.installStateHome()

	slog.Debug("Removing install directory", slog.String("path", installHome))
	err := os.RemoveAll(installHome)
	if err != nil {
		return err
	}
	return nil
}

func (env *InstallEnv) WriteSpec(force bool) error {
	specPath := env.SpecPath()

	if force {
		// Remove the old file if it exists
		_ = os.Remove(specPath)
	}
	// Write the spec
	err := env.Spec.WriteToPath(specPath)
	if err != nil {
		return err
	}
	return nil
}

func (env *InstallEnv) WriteSummary(force bool) error {
	summaryPath := env.SummaryPath()

	if force {
		// Remove the old file if it exists
		_ = os.Remove(summaryPath)
	}
	err := env.Spec.WriteStateSummary(summaryPath)
	if err != nil {
		return err
	}
	return nil
}

func (env *InstallEnv) WriteKubeConfig(force bool) error {
	kubeConfigPath := env.KubeConfigPath()

	if force {
		// Remove the old file if it exists
		_ = os.Remove(kubeConfigPath)
	}

	// TODO
	// if the provider is aws then write the kubeconfig with our wrapper for keys
	// if the provider is provided then write the kubeconfig with the provided kubeconfig
	provider := env.Spec.KubeCluster.Provider

	switch provider {
	case "kind":
		env.kindClusterProvider.ExportKubeConfig(kubeConfigPath)
	}

	return nil
}

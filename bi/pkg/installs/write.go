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
	if _, err := os.Stat(specPath); err == nil {
		if force {
			slog.Debug("Removing old spec", slog.String("path", specPath))
			_ = os.Remove(specPath)
		} else {
			slog.Debug("Spec already exists", slog.String("path", specPath))
			return nil
		}
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

	if _, err := os.Stat(summaryPath); err == nil {
		// If the file exists then we don't need to write it
		if force {
			slog.Debug("Removing old summary", slog.String("path", summaryPath))
			// Remove the old file if it exists
			_ = os.Remove(summaryPath)
		} else {
			slog.Debug("Summary already exists", slog.String("path", summaryPath))
			return nil

		}
	}
	err := env.Spec.WriteStateSummary(summaryPath)
	if err != nil {
		return err
	}
	return nil
}

func (env *InstallEnv) WriteKubeConfig(force bool) error {
	kubeConfigPath := env.KubeConfigPath()

	if _, err := os.Stat(kubeConfigPath); err == nil {
		if force {
			slog.Debug("Removing old kubeconfig", slog.String("path", kubeConfigPath))
			_ = os.Remove(kubeConfigPath)
		} else {
			slog.Debug("Kubeconfig already exists", slog.String("path", kubeConfigPath))
			return nil
		}
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

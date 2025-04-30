package installs

import (
	"context"
	"fmt"
	"log/slog"
	"os"
)

func (env *InstallEnv) WriteAll(ctx context.Context) error {
	if err := env.WriteSpec(true); err != nil {
		return err
	}

	if err := env.WriteSummary(true); err != nil {
		return err
	}

	if err := env.WriteKubeConfig(ctx, true); err != nil {
		return err
	}

	if err := env.WriteWireGuardConfig(ctx, true); err != nil {
		return err
	}

	return nil
}

func (env *InstallEnv) Remove() error {
	// Remove all files in the install directory
	installHome := env.installStateHome()

	slog.Debug("Removing install directory", slog.String("path", installHome))
	if err := os.RemoveAll(installHome); err != nil {
		return fmt.Errorf("error removing install directory: %w", err)
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
	if err := env.Spec.WriteToPath(specPath); err != nil {
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

	if err := env.Spec.WriteStateSummary(summaryPath); err != nil {
		return fmt.Errorf("error writing state summary: %w", err)
	}

	return nil
}

func (env *InstallEnv) WriteKubeConfig(ctx context.Context, force bool) error {
	kubeConfigPath := env.KubeConfigPath()

	slog.Debug("Writing kubeconfig", slog.String("path", kubeConfigPath))

	if _, err := os.Stat(kubeConfigPath); err == nil {
		if force {
			slog.Debug("Removing old kubeconfig", slog.String("path", kubeConfigPath))
			_ = os.Remove(kubeConfigPath)
		} else {
			slog.Debug("Kubeconfig already exists", slog.String("path", kubeConfigPath))
			return nil
		}
	}

	kubeConfigFile, err := os.OpenFile(kubeConfigPath, os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		return fmt.Errorf("failed to open kubeconfig file for writing: %w", err)
	}
	defer kubeConfigFile.Close()

	provider := env.Spec.KubeCluster.Provider

	switch provider {
	case "aws", "kind":
		// Kind does not use wireguard, so we'll need an external kubeconfig.
		return env.clusterProvider.WriteKubeConfig(ctx, kubeConfigFile)
	case "provided":
	default:
		return fmt.Errorf("unknown provider: %s", provider)
	}

	return nil
}

func (env *InstallEnv) WriteWireGuardConfig(ctx context.Context, force bool) error {
	wireGuardConfigPath := env.WireGuardConfigPath()

	slog.Debug("Writing wireguard config", slog.String("path", wireGuardConfigPath))

	if _, err := os.Stat(wireGuardConfigPath); err == nil {
		if force {
			slog.Debug("Removing old wireguard config", slog.String("path", wireGuardConfigPath))
			_ = os.Remove(wireGuardConfigPath)
		} else {
			slog.Debug("Wireguard config already exists", slog.String("path", wireGuardConfigPath))
			return nil
		}
	}

	wireGuardConfigFile, err := os.OpenFile(wireGuardConfigPath, os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		return fmt.Errorf("error opening wireguard config file: %w", err)
	}
	defer wireGuardConfigFile.Close()

	provider := env.Spec.KubeCluster.Provider

	var hasConfig bool
	switch provider {
	case "aws", "kind":
		hasConfig, err = env.clusterProvider.WriteWireGuardConfig(ctx, wireGuardConfigFile)
		if err != nil {
			return fmt.Errorf("error writing wireguard config: %w", err)
		}
	case "provided":
	default:
		return fmt.Errorf("unknown provider: %s", provider)
	}

	if !hasConfig {
		slog.Debug("No wireguard config to write")
		_ = wireGuardConfigFile.Close()
		_ = os.Remove(wireGuardConfigPath)
	}

	return nil
}

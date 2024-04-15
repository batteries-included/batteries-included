package installs

import (
	"path/filepath"

	"github.com/adrg/xdg"
)

func (env *InstallEnv) SummaryPath() string {
	return filepath.Join(xdg.StateHome, "bi", "installs", env.Slug, "summary.json")
}

func (env *InstallEnv) SpecPath() string {
	return filepath.Join(xdg.StateHome, "bi", "installs", env.Slug, "spec.json")
}

func (env *InstallEnv) KubeConfigPath() string {
	return filepath.Join(xdg.StateHome, "bi", "installs", env.Slug, "kubeconfig.yaml")
}

func (env *InstallEnv) WireGuardConfigPath() string {
	return filepath.Join(xdg.StateHome, "bi", "installs", env.Slug, "wireguard.yaml")
}

func (env *InstallEnv) installStateHome() string {
	return filepath.Join(xdg.StateHome, "bi", "installs", env.Slug)
}

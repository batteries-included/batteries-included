package installs

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/adrg/xdg"
)

func (env *InstallEnv) SummaryPath() string {
	return filepath.Join(xdg.StateHome, "bi", "installs", env.Slug, "summary.json")
}

func (env *InstallEnv) SpecPath() string {
	return filepath.Join(xdg.StateHome, "bi", "installs", env.Slug, "spec.json")
}

func (env *InstallEnv) BaseLogPath() string {
	return filepath.Join(xdg.StateHome, "bi", "installs", env.Slug, "logs")
}

func (env *InstallEnv) DebugLogPath(cmdPath string) string {
	now := time.Now()
	pid := os.Getpid()

	logFilename := fmt.Sprintf("%d-%d-%s.log",
		now.Unix(), pid, strings.ReplaceAll(cmdPath, " ", "-"))

	return filepath.Join(xdg.StateHome, "bi", "installs", env.Slug, "logs", logFilename)
}

func (env *InstallEnv) KubeConfigPath() string {
	return filepath.Join(xdg.StateHome, "bi", "installs", env.Slug, "kubeconfig.yaml")
}

func (env *InstallEnv) WireGuardConfigPath() string {
	return filepath.Join(xdg.StateHome, "bi", "installs", env.Slug, "wireguard.yaml")
}

func (env *InstallEnv) InstallStateHome() string {
	return filepath.Join(xdg.StateHome, "bi", "installs", env.Slug)
}

func baseInstallPath() string {
	return filepath.Join(xdg.StateHome, "bi", "installs")
}

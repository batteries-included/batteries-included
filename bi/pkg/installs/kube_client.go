package installs

import (
	"bi/pkg/kube"
	"os"
)

func (env *InstallEnv) NewBatteryKubeClient() (kube.KubeClient, error) {
	wireGuardConfigPath := env.WireGuardConfigPath()

	// Check if there is a wireguard config present.
	if _, err := os.Stat(wireGuardConfigPath); err != nil {
		wireGuardConfigPath = ""
	}

	return kube.NewBatteryKubeClient(env.KubeConfigPath(), wireGuardConfigPath)
}

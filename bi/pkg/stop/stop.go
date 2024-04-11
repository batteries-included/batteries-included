package stop

import (
	"log/slog"

	"bi/pkg/installs"
)

func StopInstall(url string) error {
	// Get the install spec
	env, err := installs.NewEnv(url)
	if err != nil {
		return err
	}

	slog.Debug("Stopping kube provider")
	err = env.StopKubeProvider()
	if err != nil {
		return err
	}

	slog.Debug("Removing install and all keys")
	err = env.Remove()
	if err != nil {
		return err
	}

	return nil
}

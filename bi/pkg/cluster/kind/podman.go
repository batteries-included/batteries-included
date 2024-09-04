package kind

import (
	"log/slog"
	"os/exec"
)

func IsPodmanAvailable() (bool, error) {
	cmd := exec.Command("podman", "info")
	err := cmd.Run()
	if err != nil {
		return false, err
	}
	slog.Debug("Podman is available")
	return true, nil
}

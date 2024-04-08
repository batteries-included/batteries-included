package cmdutil

import (
	"os"
	"path/filepath"

	"github.com/adrg/xdg"
	"github.com/spf13/cobra"
)

func DefaultWireGuardConfigPath() (string, error) {
	wireGuardConfigPath, err := xdg.ConfigFile("bi/wireguard.yaml")
	if err != nil {
		return "", err
	}

	// Make sure the parent directory exists.
	if err := os.MkdirAll(filepath.Dir(wireGuardConfigPath), 0o700); err != nil {
		return "", err
	}

	return wireGuardConfigPath, nil
}

func AddWireGuardConfigFlag(cmd *cobra.Command) {
	cmd.PersistentFlags().String("wireguard-config", "", "The wireguard config to use (default is $XDG_CONFIG_HOME/bi/wireguard.yaml)")
}

package cmdutil

import (
	"github.com/adrg/xdg"
	"github.com/spf13/cobra"
)

func AddWireGuardConfigFlag(cmd *cobra.Command) {
	wireGuardConfigPath, _ := xdg.ConfigFile("bi/wireguard.yaml")
	cmd.PersistentFlags().String("wireguard-config", wireGuardConfigPath, "The wireguard config to use")
}

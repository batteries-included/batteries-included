package cmdutil

import (
	"github.com/spf13/cobra"
)

func AddWireGuardConfigFlag(cmd *cobra.Command) {
	cmd.PersistentFlags().String("wireguard-config", "", "The wireguard config to use")
}

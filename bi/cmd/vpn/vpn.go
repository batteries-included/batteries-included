package vpn

import (
	"bi/cmd"

	"github.com/spf13/cobra"
)

var vpnCmd = &cobra.Command{
	Use:   "vpn",
	Short: "Manage the WireGuard VPN for a batteries included environment",
}

func init() {
	cmd.RootCmd.AddCommand(vpnCmd)
}

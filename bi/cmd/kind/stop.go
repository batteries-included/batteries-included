/*
Copyright © 2024 Elliott Clark @ Batteries Included
*/
package kind

import (
	"bi/pkg/local"
	"log/slog"

	"github.com/spf13/cobra"
)

var stopLocalCmd = &cobra.Command{
	Use:   "stop",
	Short: "Stop all locally running batteries included clusters",
	Long: `Batteries Included is built on top of
Kubernetes; this stops all kubernetes clusters locally
with just docker as a dependency.`,
	Run: func(cmd *cobra.Command, args []string) {
		slog.Debug("stop local called")
		clusterName, err := cmd.Flags().GetString("name")
		cobra.CheckErr(err)

		kp, err := local.NewKindClusterProvider(clusterName)
		cobra.CheckErr(err)

		err = kp.EnsureDeleted()
		cobra.CheckErr(err)
	},
}

func init() {
	kindCmd.AddCommand(stopLocalCmd)
}

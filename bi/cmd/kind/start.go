/*
Copyright © 2024 Elliott Clark @ Batteries Included
*/
package kind

import (
	"bi/pkg/local"
	"log/slog"

	"github.com/spf13/cobra"
)

var startLocalCmd = &cobra.Command{
	Use:   "start",
	Short: "Start a local kubernetes cluster with minikube or kind.",
	Long: `Batteries Included is built on top of
Kubernetes; this starts a kubernetes cluster locally
with just docker as a dependency.`,
	Run: func(cmd *cobra.Command, args []string) {
		slog.Debug("kind start called")
		_, err := local.StartDefaultKindCluster()
		cobra.CheckErr(err)
	},
}

func init() {
	kindCmd.AddCommand(startLocalCmd)
}

/*
Copyright © 2024 Elliott Clark @ Batteries Included
*/
package kind

import (
	"log/slog"

	"bi/pkg/local"

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
		clusterName, err := cmd.Flags().GetString("name")
		cobra.CheckErr(err)

		c, err := local.NewKindClusterProvider(clusterName)
		cobra.CheckErr(err)

		err = c.EnsureStarted()
		cobra.CheckErr(err)
	},
}

func init() {
	kindCmd.AddCommand(startLocalCmd)
}

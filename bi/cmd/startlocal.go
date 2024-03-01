/*
Copyright © 2024 Elliott Clark @ Batteries Included
*/
package cmd

import (
	"bi/pkg/local"
	"fmt"

	"github.com/spf13/cobra"
)

// startLocalCmd represents the startLocal command
var startLocalCmd = &cobra.Command{
	Use:   "startlocal",
	Short: "Start a local kubernetes cluster with minikube or kind.",
	Long: `Batteries Included is built on top of
Kubernetes; this starts a kubernetes cluster locally
with just docker as a dependency.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("startlocal called")
		kp, err := local.NewKindClusterProvider("bi")
		cobra.CheckErr(err)

		err = kp.EnsureStarted()
		cobra.CheckErr(err)
	},
}

func init() {
	rootCmd.AddCommand(startLocalCmd)
}

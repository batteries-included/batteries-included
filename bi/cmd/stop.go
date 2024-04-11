/*
Copyright © 2024 Elliott Clark <elliott@batteriesincl.com>
*/
package cmd

import (
	"path/filepath"

	"bi/pkg/stop"

	"github.com/spf13/cobra"
	"k8s.io/client-go/util/homedir"
)

var stopCmd = &cobra.Command{
	Use:   "stop [install-slug|install-spec-url|install-spec-file]",
	Short: "Stop the Batteries Included Installation",
	Long:  ``,
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		installUrl := args[0]

		err := stop.StopInstall(installUrl)
		cobra.CheckErr(err)
	},
}

func init() {
	RootCmd.AddCommand(stopCmd)
	// The current user homedir
	if dirname := homedir.HomeDir(); dirname == "" {
		stopCmd.Flags().StringP("kubeconfig", "k", "/", "The kubeconfig to use")
	} else {
		defaultKubeConfig := filepath.Join(dirname, ".kube", "config")
		stopCmd.PersistentFlags().StringP("kubeconfig", "k", defaultKubeConfig, "The kubeconfig to use")
	}
}

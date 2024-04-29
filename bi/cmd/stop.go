/*
Copyright © 2024 Elliott Clark <elliott@batteriesincl.com>
*/
package cmd

import (
	"path/filepath"

	"bi/pkg/installs"
	"bi/pkg/log"
	"bi/pkg/stop"

	"github.com/spf13/cobra"
	"k8s.io/client-go/util/homedir"
)

var stopCmd = &cobra.Command{
	Use:   "stop [install-slug|install-spec-url|install-spec-file]",
	Short: "Stop the Batteries Included Installation",
	Long:  ``,
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		installURL := args[0]

		ctx := cmd.Context()
		env, err := installs.NewEnv(ctx, installURL)
		if err != nil {
			return err
		}

		if err := log.CollectDebugLogs(env.DebugLogPath(cmd.CommandPath())); err != nil {
			return err
		}

		return stop.StopInstall(ctx, env)
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

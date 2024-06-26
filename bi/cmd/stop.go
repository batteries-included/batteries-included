/*
Copyright © 2024 Elliott Clark <elliott@batteriesincl.com>
*/
package cmd

import (
	"bi/pkg/installs"
	"bi/pkg/log"
	"bi/pkg/stop"

	"github.com/spf13/cobra"
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

		skipCleanKube, err := cmd.Flags().GetBool("skip-clean-kube")
		if err != nil {
			return err
		}

		return stop.StopInstall(ctx, env, skipCleanKube)
	},
}

func init() {
	RootCmd.AddCommand(stopCmd)
	stopCmd.Flags().Bool("skip-clean-kube", false, "Skip deleting kubernetes resources")
}

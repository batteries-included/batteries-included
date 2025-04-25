/*
Copyright © 2024 Elliott Clark elliott@batteriesincl.com
*/
package debug

import (
	"bi/pkg/installs"
	"bi/pkg/log"

	"github.com/spf13/cobra"
)

var cleanKubeCmd = &cobra.Command{
	Use:   "clean-kube [install-slug|install-spec-url|install-spec-file]",
	Short: "clean all resources off of a batteries included kubernetes cluster",
	Args:  cobra.MatchAll(cobra.ExactArgs(1), cobra.OnlyValidArgs),
	RunE: func(cmd *cobra.Command, args []string) error {
		url := args[0]
		ctx := cmd.Context()

		env, err := installs.NewEnv(ctx, url)
		if err != nil {
			return err
		}

		if err := log.CollectDebugLogs(env.DebugLogPath(cmd.CommandPath())); err != nil {
			return err
		}

		kubeClient, err := env.NewBatteryKubeClient()
		if err != nil {
			return err
		}
		defer kubeClient.Close()

		if err := kubeClient.RemoveAll(ctx); err != nil {
			return err
		}

		return nil
	},
}

func init() {
	debugCmd.AddCommand(cleanKubeCmd)
}

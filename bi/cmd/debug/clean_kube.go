/*
Copyright © 2024 Elliott Clark elliott@batteriesincl.com
*/
package debug

import (
	"bi/pkg/installs"

	"github.com/spf13/cobra"
)

var cleanKubeCmd = &cobra.Command{
	Use:   "clean-kube [install-slug|install-spec-url|install-spec-file]",
	Short: "clean all resources off of a batteries included kubernetes cluster",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		url := args[0]
		ctx := cmd.Context()

		env, err := installs.NewEnv(ctx, url)
		cobra.CheckErr(err)

		kubeClient, err := env.NewBatteryKubeClient()
		cobra.CheckErr(err)
		defer kubeClient.Close()

		cobra.CheckErr(kubeClient.RemoveAll(ctx))
	},
}

func init() {
	debugCmd.AddCommand(cleanKubeCmd)
}

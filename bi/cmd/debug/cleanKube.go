/*
Copyright © 2024 Elliott Clark elliott@batteriesincl.com
*/
package debug

import (
	"bi/cmd/cmdutil"
	"bi/pkg/kube"

	"github.com/spf13/cobra"
)

var cleanKubeCmd = &cobra.Command{
	Use:   "clean-kube",
	Short: "clean all resources off of a batteries included kubernetes cluster",
	Run: func(cmd *cobra.Command, args []string) {

		kubeConfigPath, err := cmd.Flags().GetString("kubeconfig")
		cobra.CheckErr(err)

		wireGuardConfigPath, err := cmd.Flags().GetString("wireguard-config")
		cobra.CheckErr(err)

		kubeClient, err := kube.NewBatteryKubeClient(kubeConfigPath, wireGuardConfigPath)
		cobra.CheckErr(err)
		defer kubeClient.Close()

		err = kubeClient.RemoveAll()
		cobra.CheckErr(err)
	},
}

func init() {
	debugCmd.AddCommand(cleanKubeCmd)
	cmdutil.AddKubeConfigFlag(cleanKubeCmd)
	cmdutil.AddWireGuardConfigFlag(cleanKubeCmd)
}

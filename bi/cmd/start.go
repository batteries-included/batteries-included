/*
Copyright © 2024 Elliott Clark <elliott@batteriesincl.com>
*/
package cmd

import (
	"bi/cmd/cmdutil"
	"bi/pkg/start"

	"log/slog"

	"github.com/spf13/cobra"
)

// startCmd represents the start command
var startCmd = &cobra.Command{
	Use:   "start [install-spec]",
	Short: "Start a Batteries Included Installation",
	Long: `This will get the configuration for the
	installation and start the installation process.

	If the installation is already started, it will
	complete the installation and sync all resources
	that should be created but weren't.

	First step is to ensure the kubernetes cluster is started as specified.

	The options are:

	- Start an EKS cluster
	- Start a local kubernetes cluster using Kind and docker
	- Use an existing kubernetes cluster

	Then all the bootstrap resources are created.

	Then the cli waits until the installation is
	complete displaying a url for running control server.`,
	Args: cobra.MinimumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		installUrl := args[0]

		kubeConfigPath, err := cmd.Flags().GetString("kubeconfig")
		cobra.CheckErr(err)

		writeStateSummaryPath, err := cmd.Flags().GetString("write-state-summary")
		cobra.CheckErr(err)

		slog.Debug("Starting Batteries Included Installation",
			slog.String("installSpec", installUrl),
			slog.String("kubeconfig", kubeConfigPath),
			slog.String("writeStateSummary", writeStateSummaryPath))

		err = start.StartInstall(installUrl, kubeConfigPath, writeStateSummaryPath)
		cobra.CheckErr(err)
	},
}

func init() {
	RootCmd.AddCommand(startCmd)
	cmdutil.AddKubeConfigFlag(startCmd)
	startCmd.Flags().StringP("write-state-summary", "S", "", "Write a StateSummary that's used for bootstrapping")
}

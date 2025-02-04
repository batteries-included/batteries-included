/*
Copyright © 2024 Elliott Clark <elliott@batteriesincl.com>
*/
package cmd

import (
	"bi/pkg/installs"
	"bi/pkg/log"
	"bi/pkg/start"

	"log/slog"

	"github.com/spf13/cobra"
)

// startCmd represents the start command
var startCmd = &cobra.Command{
	Use:   "start [install-slug|install-spec-url|install-spec-file]",
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
	RunE: func(cmd *cobra.Command, args []string) error {
		installURL := args[0]

		slog.Debug("Starting Batteries Included Installation",
			slog.String("installSpec", installURL))

		ctx := cmd.Context()
		env, err := installs.NewEnv(ctx, installURL)
		if err != nil {
			return err
		}

		if err := log.CollectDebugLogs(env.DebugLogPath(cmd.CommandPath())); err != nil {
			return err
		}

		skipBootstrap, err := cmd.Flags().GetBool("skip-bootstrap")
		if err != nil {
			return err
		}

		return start.StartInstall(ctx, env, skipBootstrap)
	},
}

func init() {
	RootCmd.AddCommand(startCmd)
	startCmd.Flags().Bool("skip-bootstrap", false, "Skip bootstrapping the cluster")
}

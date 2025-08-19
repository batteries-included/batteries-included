/*
Copyright © 2024 Elliott Clark <elliott@batteriesincl.com>
*/
package cmd

import (
	"context"
	"log/slog"

	"bi/pkg/installs"
	"bi/pkg/log"
	"bi/pkg/start"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// startCmd represents the start command
var startCmd = &cobra.Command{
	Use:   "start [install-slug|install-spec-url|install-spec-file] [flags]",
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
	Args: cobra.MatchAll(cobra.ExactArgs(1), cobra.OnlyValidArgs),
	RunE: func(cmd *cobra.Command, args []string) error {
		installURL := args[0]

		slog.Debug("Starting Batteries Included Installation",
			slog.String("installSpec", installURL))

		ctx, cancel := context.WithCancel(cmd.Context())
		defer cancel()

		// Use Viper to get all configuration values with proper precedence
		additionalHosts := viper.GetStringSlice("additional-insecure-hosts")
		nvidiaAutoDiscovery := viper.GetBool("nvidia-auto-discovery")
		allowTestKeys := viper.GetBool("allow-test-keys")
		skipBootstrap := viper.GetBool("skip-bootstrap")

		eb := installs.NewEnvBuilder(
			installs.WithSlugOrURL(installURL),
			installs.WithAdditionalInsecureHosts(additionalHosts),
			installs.WithNvidiaAutoDiscovery(nvidiaAutoDiscovery),
			installs.WithAllowTestKeys(allowTestKeys),
		)
		env, err := eb.Build(ctx)
		if err != nil {
			return err
		}

		err = env.Init(ctx, true)
		if err != nil {
			return err
		}

		if err := log.CollectDebugLogs(env.DebugLogPath(cmd.CommandPath())); err != nil {
			return err
		}

		return start.StartInstall(ctx, env, skipBootstrap)
	},
}

func init() {
	RootCmd.AddCommand(startCmd)

	// Define local flags
	startCmd.Flags().Bool("skip-bootstrap", false, "Skip bootstrapping the cluster")
	startCmd.Flags().Bool("nvidia-auto-discovery", true, "Enable NVIDIA GPU auto-discovery for Kind clusters")
	startCmd.Flags().Bool("allow-test-keys", false, "Allow test keys for JWT verification when fetching specs (default: production keys only)")
	startCmd.Flags().StringSlice("additional-insecure-hosts", []string{}, "Additional hosts that will be allowed to be insecure - HTTP")
	_ = startCmd.Flags().MarkHidden("additional-insecure-hosts")

	// Bind flags to Viper
	viper.BindPFlag("skip-bootstrap", startCmd.Flags().Lookup("skip-bootstrap"))
	viper.BindPFlag("nvidia-auto-discovery", startCmd.Flags().Lookup("nvidia-auto-discovery"))
	viper.BindPFlag("allow-test-keys", startCmd.Flags().Lookup("allow-test-keys"))
	viper.BindPFlag("additional-insecure-hosts", startCmd.Flags().Lookup("additional-insecure-hosts"))
}

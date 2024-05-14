package cmd

import (
	"bi/pkg/installs"
	"bi/pkg/log"
	"bi/pkg/rage"
	"log/slog"

	"github.com/spf13/cobra"
)

var rageCmd = &cobra.Command{
	Use:   "rage [install-slug|install-spec-url|install-spec-file]",
	Short: "Rage against the machine",
	Args:  cobra.MinimumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		installURL := args[0]

		slog.Debug("Raging against the machine",
			slog.String("installSpec", installURL))

		ctx := cmd.Context()
		env, err := installs.NewEnv(ctx, installURL)
		if err != nil {
			return err
		}

		if err := log.CollectDebugLogs(env.DebugLogPath(cmd.CommandPath())); err != nil {
			return err
		}

		maxLogs, err := cmd.Flags().GetInt("max-logs")
		if err != nil {
			return err
		}

		return rage.Rage(ctx, env, maxLogs)
	},
}

func init() {
	rageCmd.Flags().IntP("max-logs", "n", 10, "The maximum number of debug logs to include in the rage archive")

	RootCmd.AddCommand(rageCmd)
}

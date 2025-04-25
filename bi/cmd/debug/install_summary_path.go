/*
Copyright © 2024 Elliott Clark elliott@batteriesincl.com
*/
package debug

import (
	"fmt"

	"bi/pkg/installs"
	"bi/pkg/log"

	"github.com/spf13/cobra"
)

var installSummaryPath = &cobra.Command{
	Use:   "install-summary-path [install-slug|install-spec-url|install-spec-file]",
	Short: "Print the path to the install's target summary",
	Args:  cobra.MatchAll(cobra.ExactArgs(1), cobra.OnlyValidArgs),
	RunE: func(cmd *cobra.Command, args []string) error {
		env, err := installs.NewEnv(cmd.Context(), args[0])
		if err != nil {
			return err
		}

		if err := log.CollectDebugLogs(env.DebugLogPath(cmd.CommandPath())); err != nil {
			return err
		}

		fmt.Print(env.SummaryPath())

		return nil
	},
}

func init() {
	debugCmd.AddCommand(installSummaryPath)
}

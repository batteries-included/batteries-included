/*
Copyright © 2024 Elliott Clark elliott@batteriesincl.com
*/
package debug

import (
	"fmt"

	"bi/pkg/installs"

	"github.com/spf13/cobra"
)

var installSummaryPath = &cobra.Command{
	Use:   "install-summary-path [install-slug|install-spec-url|install-spec-file]",
	Short: "Print the path to the install's target summary",
	Run: func(cmd *cobra.Command, args []string) {
		env, err := installs.NewEnv(cmd.Context(), args[0])
		cobra.CheckErr(err)

		fmt.Print(env.SummaryPath())
	},
}

func init() {
	debugCmd.AddCommand(installSummaryPath)
}

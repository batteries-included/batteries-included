/*
Copyright © 2024 Batteries Inluded <elliott@batteriesincl.com>
*/
package debug

import (
	"bi/pkg/specs"
	"fmt"
	"log/slog"
	"os"

	"github.com/spf13/cobra"
)

var specToSummaryCmd = &cobra.Command{
	Use:   "spec-summary [install-spec]",
	Short: "Write an target state summary file based on the install spec file",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		writeStateSummaryPath, err := cmd.Flags().GetString("write-state-summary")
		cobra.CheckErr(err)

		spec, err := specs.GetSpecFromURL(args[0])
		cobra.CheckErr(err)

		contents, err := spec.TargetSummary.UnmarshalJSON()
		cobra.CheckErr(err)

		if writeStateSummaryPath != "" {
			slog.Debug("Writing state summary to", slog.String("path", writeStateSummaryPath))
			err = os.WriteFile(writeStateSummaryPath, contents, 0644)
			cobra.CheckErr(err)
		} else {
			fmt.Print(contents)
		}
	},
}

func init() {
	debugCmd.AddCommand(specToSummaryCmd)
	specToSummaryCmd.Flags().StringP("write-state-summary", "S", "", "Write a StateSummary that's used for bootstrapping")
}

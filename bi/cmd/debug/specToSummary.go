/*
Copyright © 2024 Batteries Inluded <elliott@batteriesincl.com>
*/
package debug

import (
	"encoding/json"
	"fmt"
	"log/slog"

	"bi/pkg/specs"

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

		if writeStateSummaryPath != "" {
			slog.Debug("Writing state summary to", slog.String("path", writeStateSummaryPath))
			err = spec.WriteStateSummary(writeStateSummaryPath)
			cobra.CheckErr(err)
		} else {
			contents, err := json.Marshal(spec.TargetSummary)
			cobra.CheckErr(err)

			fmt.Print(contents)
		}
	},
}

func init() {
	debugCmd.AddCommand(specToSummaryCmd)
	specToSummaryCmd.Flags().StringP("write-state-summary", "S", "", "Write a StateSummary that's used for bootstrapping")
}

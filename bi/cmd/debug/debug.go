/*
Copyright © 2024 Batteries Inluded
*/
package debug

import (
	"bi/cmd"

	"github.com/spf13/cobra"
)

var debugCmd = &cobra.Command{
	Use:   "debug",
	Short: "Utilities for debugging",
	Long: `Tools to help debugging the current state of 
	an installation of batteries included`,
	Run: func(cmd *cobra.Command, args []string) {
	},
}

func init() {
	cmd.RootCmd.AddCommand(debugCmd)
}

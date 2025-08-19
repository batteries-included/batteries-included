/*
Copyright © 2025 Batteries Inluded
*/
package cli

import (
	"bi/cmd"

	"github.com/spf13/cobra"
)

var cliCmd = &cobra.Command{
	Use:   "cli",
	Short: "Utilities for the bi binary and CLI commands",
	Long: `Tools to help manage and interact with the bi binary
	and command line interface utilities`,
}

func init() {
	cmd.RootCmd.AddCommand(cliCmd)
}

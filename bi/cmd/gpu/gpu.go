/*
Copyright © 2025 Batteries Inluded
*/
package gpu

import (
	"bi/cmd"

	"github.com/spf13/cobra"
)

var gpuCommand = &cobra.Command{
	Use:   "gpu",
	Short: "Utilities for managing GPUs",
	Long: `Tools to help manage and interact with GPUs in the
	batteries included environment`,
}

func init() {
	cmd.RootCmd.AddCommand(gpuCommand)
}

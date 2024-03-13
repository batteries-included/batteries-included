/*
Copyright © 2024 Batteries Included
*/
package kind

import (
	"bi/cmd"

	"github.com/spf13/cobra"
)

var kindCmd = &cobra.Command{
	Use:   "kind",
	Short: "A brief description of your command",
	Long:  ``,
	Run: func(cmd *cobra.Command, args []string) {
	},
}

func init() {
	cmd.RootCmd.AddCommand(kindCmd)
}

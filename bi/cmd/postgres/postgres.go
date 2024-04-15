/*
Copyright © 2024 Batteries Included <elliott@batteriesincl.com>
*/
package postgres

import (
	"bi/cmd"

	"github.com/spf13/cobra"
)

// postgresCmd represents the postgres command
var postgresCmd = &cobra.Command{
	Use:   "postgres",
	Short: "Tools to interact with postgres databases",
	Long: `Tools to interact with postgres databases. For example:

	- Port forwarding to a postgres database on a local kube cluster
	- Checking the status of a postgres database`,
}

func init() {
	cmd.RootCmd.AddCommand(postgresCmd)
}

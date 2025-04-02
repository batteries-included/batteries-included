/*
Copyright © 2024 Batteries Included <elliott@batteriesincl.com>
*/
package cmd

import (
	"bi/pkg/installs"
	"fmt"
	"path/filepath"
	"time"

	"github.com/adrg/xdg"
	"github.com/spf13/cobra"
)

// rageCmd represents the rage command
//
// This command is used to collect debug information when things go wrong.
var rageCmd = &cobra.Command{
	Use:   "rage [install-slug|install-spec-url|install-spec-file]",
	Short: "Collect debug information when things go wrong",
	RunE: func(cmd *cobra.Command, args []string) error {
		installURL := args[0]

		ctx := cmd.Context()
		env, err := installs.NewEnv(ctx, installURL)
		if err != nil {
			return err
		}
		rageReport, err := env.NewRage(ctx)
		if err != nil {
			return err
		}

		logFilename := fmt.Sprintf("%d.json", time.Now().Unix())

		path := filepath.Join(xdg.StateHome, "bi", "rage", logFilename)
		err = rageReport.Write(path)
		if err != nil {
			return err
		}

		fmt.Println(path)
		return nil
	},
}

func init() {
	RootCmd.AddCommand(rageCmd)
}

/*
Copyright © 2024 Elliott Clark elliott@batteriesincl.com
*/
package debug

import (
	"bi/pkg/specs"
	"fmt"
	"log/slog"
	"os"

	"github.com/spf13/cobra"
)

var verifySpecCmd = &cobra.Command{
	Use:   "verifyspec",
	Short: "Verify an install spec file",
	Long:  `Reads in an install spec file and verifies that it is valid.`,
	Run: func(cmd *cobra.Command, args []string) {
		for _, path_name := range args {
			err := verifyFile(path_name)
			if err != nil {
				fmt.Println(err)
				os.Exit(1)
			}
			fmt.Println("verified", path_name)
		}
	},
}

func verifyFile(pathName string) error {
	var data, err = os.ReadFile(pathName)
	if err != nil {
		return err
	}

	var _, json_err = specs.UnmarshalJSON(data)
	if json_err != nil {
		slog.Error("unable to pasrse spec into struct", "error", json_err)
		return err
	}

	return nil
}

func init() {
	debugCmd.AddCommand(verifySpecCmd)
}

/*
Copyright © 2024 Elliott Clark elliott@batteriesincl.com
*/
package debug

import (
	"fmt"
	"os"

	"bi/pkg/specs"

	"github.com/spf13/cobra"
)

var verifySpecCmd = &cobra.Command{
	Use:   "verify-spec",
	Short: "Verify an install spec file",
	Long:  `Reads in an install spec file and verifies that it is valid.`,
	Run: func(cmd *cobra.Command, args []string) {
		for _, pathName := range args {
			err := verifyFile(pathName)
			cobra.CheckErr(err)

			fmt.Println("Verified:", pathName)
		}
	},
}

func verifyFile(pathName string) error {
	data, err := os.ReadFile(pathName)
	if err != nil {
		return fmt.Errorf("unable to read spec file: %w", err)
	}

	if _, err := specs.UnmarshalJSON(data); err != nil {
		return fmt.Errorf("unable to unmarshal spec file: %w", err)
	}

	return nil
}

func init() {
	debugCmd.AddCommand(verifySpecCmd)
}

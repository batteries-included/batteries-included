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
	Use:   "verify-spec [install-slug|install-spec-url|install-spec-file]",
	Short: "Verify an install spec file",
	Long:  `Reads in an install spec file and verifies that it is valid.`,
	Args:  cobra.MatchAll(cobra.ExactArgs(1), cobra.OnlyValidArgs),
	RunE: func(cmd *cobra.Command, args []string) error {
		for _, pathName := range args {
			if err := verifyFile(pathName); err != nil {
				return err
			}

			fmt.Println("Verified:", pathName)
		}

		return nil
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

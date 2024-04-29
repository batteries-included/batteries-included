/*
Copyright © 2024 Elliott Clark elliott@batteriesincl.com
*/
package debug

import (
	"fmt"

	"bi/pkg/specs"

	"github.com/spf13/cobra"
)

var specSlugCmd = &cobra.Command{
	Use:   "spec-slug",
	Short: "Reads in an install spec file and prints the slug",
	RunE: func(cmd *cobra.Command, args []string) error {
		spec, err := specs.GetSpecFromURL(args[0])
		if err != nil {
			return err
		}

		fmt.Println(spec.Slug)

		return nil
	},
}

func init() {
	debugCmd.AddCommand(specSlugCmd)
}

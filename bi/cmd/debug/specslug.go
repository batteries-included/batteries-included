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
	Run: func(cmd *cobra.Command, args []string) {
		spec, err := specs.GetSpecFromURL(args[0])
		cobra.CheckErr(err)

		fmt.Println(spec.Slug)
	},
}

func init() {
	debugCmd.AddCommand(specSlugCmd)
}

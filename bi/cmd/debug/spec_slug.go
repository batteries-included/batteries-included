/*
Copyright © 2024 Elliott Clark elliott@batteriesincl.com
*/
package debug

import (
	"fmt"

	"bi/pkg/jwt"
	"bi/pkg/specs"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var specSlugCmd = &cobra.Command{
	Use:   "spec-slug [install-spec-url|install-spec-file]",
	Short: "Reads in an install spec file and prints the slug",
	Args:  cobra.MatchAll(cobra.ExactArgs(1), cobra.OnlyValidArgs),
	RunE: func(cmd *cobra.Command, args []string) error {
		// Use Viper to get allow-test-keys with proper precedence
		allowTestKeys := viper.GetBool("allow-test-keys")

		// Create JWT verifier based on configuration
		verifier := jwt.NewVerifier(allowTestKeys)

		// Use the new SpecFetcher with JWT verification
		fetcher := specs.NewSpecFetcher(
			specs.WithURL(args[0]),
			specs.WithJWTVerifier(verifier),
		)

		spec, err := fetcher.Fetch()
		if err != nil {
			return err
		}

		fmt.Print(spec.Slug)

		return nil
	},
}

func init() {
	specSlugCmd.Flags().Bool("allow-test-keys", false, "Allow test keys for JWT verification (default: production keys only)")
	viper.BindPFlag("allow-test-keys", specSlugCmd.Flags().Lookup("allow-test-keys"))

	debugCmd.AddCommand(specSlugCmd)
}

package debug

import (
	"context"
	"encoding/json"
	"fmt"

	"bi/pkg/jwt"
	"bi/pkg/version"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	stableVersionsFormat string
)

// stableVersionsCmd represents the stable-versions command
var stableVersionsCmd = &cobra.Command{
	Use:   "stable-versions",
	Short: "Show stable versions",
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx := context.Background()

		// Get allow-test-keys from Viper
		allowTestKeys := viper.GetBool("allow-test-keys")

		// Create version fetcher with JWT verification
		verifier := jwt.NewVerifier(allowTestKeys)
		fetcher := version.NewVersionFetcher(version.WithJWTVerifier(verifier))

		// Get stable versions
		versions, err := fetcher.GetStableVersions(ctx)
		if err != nil {
			return fmt.Errorf("getting stable versions: %w", err)
		}

		// Pretty print the versions
		jsonBytes, err := json.MarshalIndent(versions, "", "  ")
		if err != nil {
			return fmt.Errorf("marshaling versions: %w", err)
		}
		fmt.Println(string(jsonBytes))

		return nil
	},
}

func init() {
	stableVersionsCmd.Flags().StringVar(&stableVersionsFormat, "format", "text", "Output format (text or json)")
	stableVersionsCmd.Flags().Bool("allow-test-keys", false, "Allow test keys for JWT verification (default: production keys only)")
	stableVersionsCmd.Flags().MarkHidden("allow-test-keys")
	debugCmd.AddCommand(stableVersionsCmd)
}

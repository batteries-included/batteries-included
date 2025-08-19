package cli

import (
	"bi/pkg/jwt"
	"bi/pkg/update"
	"bi/pkg/version"
	"context"
	"fmt"
	"path/filepath"

	"github.com/adrg/xdg"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	updateLatest    bool
	updateDataHome  string
	updateBinHome   string
	updateForceLink bool
)

var updateCmd = &cobra.Command{
	Use:   "update",
	Short: "Update the bi binary to the latest stable or latest version",
	Long: `Update the bi binary to the latest stable version from the batteries included API,
or to the latest release from GitHub.

This command fetches the current stable version from the batteries included API
and installs it using the same mechanism as the install command.

By default, this uses:
- Data home: ~/.local/share/bi (XDG_DATA_HOME/bi)
- Bin home: ~/.local/bin (XDG_BIN_HOME or ~/.local/bin)

Examples:
  bi cli update                    # Update to latest stable version
  bi cli update --latest           # Update to latest GitHub release
  bi cli update --force-link       # Force linking even if version is not newer`,
	Args: cobra.NoArgs,
	RunE: runUpdate,
}

func init() {
	updateCmd.Flags().BoolVar(&updateLatest, "latest", false,
		"Update to latest GitHub release instead of stable version")
	updateCmd.Flags().BoolVar(&updateForceLink, "force-link", false,
		"Force linking even if the new version is not newer")
	updateCmd.Flags().Bool("allow-test-keys", false,
		"Allow test keys for JWT verification when fetching stable version (default: production keys only)")
	updateCmd.Flags().StringVar(&updateDataHome, "data-home", "",
		"Data directory for installation (default: XDG_DATA_HOME/bi)")
	updateCmd.Flags().StringVar(&updateBinHome, "bin-home", "",
		"Bin directory for installation (default: XDG_BIN_HOME or ~/.local/bin)")

	// Bind flags to Viper
	viper.BindPFlag("allow-test-keys", updateCmd.Flags().Lookup("allow-test-keys"))

	cliCmd.AddCommand(updateCmd)
}

func runUpdate(cmd *cobra.Command, args []string) error {
	// Set default directories using XDG standards
	dataHome := updateDataHome
	if dataHome == "" {
		dataHome = filepath.Join(xdg.DataHome, "bi")
	}

	binHome := updateBinHome
	if binHome == "" {
		// XDG doesn't define a standard BIN_HOME, so we use ~/.local/bin as fallback
		binHome = filepath.Join(filepath.Dir(xdg.DataHome), "bin")
	}

	ctx := context.Background()
	var versionString string
	var err error

	// Fetch version based on flag
	if updateLatest {
		fmt.Println("Fetching latest release version...")

		// Create version fetcher for latest version (no JWT verification needed)
		fetcher := version.NewVersionFetcher()
		versionString, err = fetcher.GetLatestVersion(ctx)
		if err != nil {
			return fmt.Errorf("failed to fetch latest version: %w", err)
		}
	} else {
		fmt.Println("Fetching stable version...")

		// Use Viper to get allow-test-keys with proper precedence
		allowTestKeys := viper.GetBool("allow-test-keys")

		// Create version fetcher with JWT verification
		verifier := jwt.NewVerifier(allowTestKeys)
		fetcher := version.NewVersionFetcher(version.WithJWTVerifier(verifier))

		stableVersions, err := fetcher.GetStableVersions(ctx)
		if err != nil {
			return fmt.Errorf("failed to fetch stable version: %w", err)
		}
		versionString = stableVersions.BI
		fmt.Printf("Stable version: %s\n", versionString)
	}

	// Create installer with the fetched version
	installer := update.NewInstaller(update.InstallOptions{
		Version:     versionString,
		ForceUpdate: true, // Always force update since we're explicitly updating
		ForceLink:   updateForceLink,
		DataHome:    dataHome,
		BinHome:     binHome,
	})

	// Run installation
	if err := installer.Install(ctx); err != nil {
		return fmt.Errorf("update failed: %w", err)
	}

	fmt.Printf("Successfully updated bi to %s at %s\n", versionString, filepath.Join(binHome, "bi"))
	fmt.Printf("Make sure %s is in your PATH\n", binHome)

	return nil
}

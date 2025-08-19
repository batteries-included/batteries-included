package cli

import (
	"bi/pkg/update"
	"context"
	"fmt"
	"path/filepath"

	"github.com/adrg/xdg"
	"github.com/spf13/cobra"
)

var (
	installForceUpdate bool
	installForceLink   bool
	installDataHome    string
	installBinHome     string
)

var installCmd = &cobra.Command{
	Use:   "install <version>",
	Short: "Install or update the bi binary",
	Long: `Download and install the bi binary from GitHub releases.
This command downloads the binary for your platform, verifies its checksum,
and installs it to XDG data home with a symlink in XDG bin home.

By default, this uses:
- Data home: ~/.local/share/bi (XDG_DATA_HOME/bi)
- Bin home: ~/.local/bin (XDG_BIN_HOME or ~/.local/bin)

The version must be specified as a required argument.

Examples:
  bi cli install 1.2.3
  bi cli install 1.2.3 --force-update
  bi cli install 1.2.3 --force-link`,
	Args: cobra.ExactArgs(1),
	RunE: runInstall,
}

func init() {
	installCmd.Flags().BoolVar(&installForceUpdate, "force-update", false,
		"Force download even if the version already exists")
	installCmd.Flags().BoolVar(&installForceLink, "force-link", false,
		"Force linking even if the new version is not newer")
	installCmd.Flags().StringVar(&installDataHome, "data-home", "",
		"Data directory for installation (default: XDG_DATA_HOME/bi)")
	installCmd.Flags().StringVar(&installBinHome, "bin-home", "",
		"Bin directory for installation (default: XDG_BIN_HOME or ~/.local/bin)")

	cliCmd.AddCommand(installCmd)
}

func runInstall(cmd *cobra.Command, args []string) error {
	// Get the required version argument
	version := args[0]

	// Set default directories using XDG standards
	dataHome := installDataHome
	if dataHome == "" {
		dataHome = filepath.Join(xdg.DataHome, "bi")
	}

	binHome := installBinHome
	if binHome == "" {
		// XDG doesn't define a standard BIN_HOME, so we use ~/.local/bin as fallback
		binHome = filepath.Join(filepath.Dir(xdg.DataHome), "bin")
	}

	// Create installer
	installer := update.NewInstaller(update.InstallOptions{
		Version:     version,
		ForceUpdate: installForceUpdate,
		ForceLink:   installForceLink,
		DataHome:    dataHome,
		BinHome:     binHome,
	})

	// Run installation
	ctx := context.Background()
	if err := installer.Install(ctx); err != nil {
		return fmt.Errorf("installation failed: %w", err)
	}

	fmt.Printf("Successfully installed bi %s to %s\n", version, filepath.Join(binHome, "bi"))
	fmt.Printf("Make sure %s is in your PATH\n", binHome)

	return nil
}

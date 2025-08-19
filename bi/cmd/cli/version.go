package cli

import (
	"bi/pkg"
	"encoding/json"
	"fmt"
	"os"
	"strings"

	"github.com/spf13/cobra"
)

var (
	versionOutputFormat string
)

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Show embedded version information",
	Long: `Display detailed version and build information for the bi binary.
This command shows the embedded version and Go compiler version used to build the binary.

The command supports both text and JSON output formats for integration with other tools.`,
	RunE: runVersion,
}

func init() {
	versionCmd.Flags().StringVarP(&versionOutputFormat, "format", "f", "text",
		"Output format: 'text' for human-readable output or 'json' for machine-readable JSON")
	cliCmd.AddCommand(versionCmd)
}

func runVersion(cmd *cobra.Command, args []string) error {
	// Get version information
	versionInfo := pkg.GetVersionInfo()

	// Output in requested format
	switch strings.ToLower(versionOutputFormat) {
	case "json":
		return outputVersionAsJSON(versionInfo)
	case "text":
		return outputVersionAsText(versionInfo)
	default:
		return fmt.Errorf("unsupported output format: %s (supported: text, json)", versionOutputFormat)
	}
}

func outputVersionAsJSON(versionInfo pkg.VersionInfo) error {
	encoder := json.NewEncoder(os.Stdout)
	encoder.SetIndent("", "  ")
	return encoder.Encode(versionInfo)
}

func outputVersionAsText(versionInfo pkg.VersionInfo) error {
	fmt.Println("Build Info:")
	fmt.Println("\tVersion:", versionInfo.Version)
	fmt.Println("\tGo Version:", versionInfo.GoVersion)
	return nil
}

package debug

import (
	"bi/pkg"
	"fmt"
	"runtime/debug"

	"github.com/spf13/cobra"
)

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Show embedded version information",
	RunE: func(cmd *cobra.Command, args []string) error {
		fmt.Println("Build Info:")
		fmt.Println("\tVersion:", pkg.Version)
		info, ok := debug.ReadBuildInfo()
		if ok && info != nil {
			fmt.Println("\tGo Version:", info.GoVersion)
		}
		return nil
	},
}

func init() {
	debugCmd.AddCommand(versionCmd)
}

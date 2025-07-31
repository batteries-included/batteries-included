package local

import (
	"bi/cmd"

	"github.com/spf13/cobra"
)

var localCmd = &cobra.Command{
	Use:   "local",
	Short: "Commands for local development with various container engines",
	Long: `Commands for setting up and managing local Batteries Included 
installations with support for multiple container engines on macOS and Linux:
- Docker Desktop
- Podman 
- Colima
- Apple Virtualization`,
}

func init() {
	cmd.RootCmd.AddCommand(localCmd)
}
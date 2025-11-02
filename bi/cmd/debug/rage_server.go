/*
Copyright © 2024 Batteries Included
*/
package debug

import (
	"context"
	"fmt"
	"path/filepath"

	"github.com/adrg/xdg"
	"github.com/spf13/cobra"

	"bi/pkg/rage_server"
)

var rageServerCmd = &cobra.Command{
	Use:   "rage-server",
	Short: "Start a web server to view rage reports",
	Long: `Start a debug web server that monitors rage reports and provides
a web interface to explore the debug information.

The server will watch for JSON files in the specified directory and
provide a web interface to browse pods, networking information, and logs.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		port, err := cmd.Flags().GetInt("port")
		if err != nil {
			return err
		}

		dir, err := cmd.Flags().GetString("dir")
		if err != nil {
			return err
		}

		// Use default directory if not specified
		if dir == "" {
			dir = filepath.Join(xdg.StateHome, "bi", "rage")
		}

		server := rage_server.NewRageServer(dir, port)

		fmt.Printf("Starting rage server on http://localhost:%d\n", port)
		fmt.Printf("Watching rage directory: %s\n", dir)

		return server.Start(context.Background())
	},
}

func init() {
	rageServerCmd.Flags().IntP("port", "p", 8772, "Port to serve the web interface on")
	rageServerCmd.Flags().StringP("dir", "d", "", "Directory to watch for rage files (default: ~/.local/state/bi/rage/)")
	debugCmd.AddCommand(rageServerCmd)
}

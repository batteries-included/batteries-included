/*
Copyright © 2025 Elliott Clark
*/
package cmd

import (
	"errors"
	"os"

	"log/slog"
	"registry-tool/pkg/log"
	"registry-tool/pkg/registry"

	"github.com/spf13/cobra"
)

var verbosity string
var color bool

var RootCmd = &cobra.Command{
	Use:   "registry-tool",
	Short: "A tool to change the Batteries Included registry for OCI images",
	Long: `This tool is designed to manage the registry used by Batteries Included for their OCI images used in different batteries.
	
It allows us to have a single source of truth for versions per commit. Our registry is a YAML file that contains a 
list of images and information about them.`,
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		return log.SetupLogging(verbosity, color)
	},
}

func Execute() {
	err := RootCmd.Execute()
	switch {
	case err == nil:
		return
	case errors.Is(err, registry.ErrNoChanges):
		os.Exit(1)
	default:
		os.Exit(2)
	}
}

func init() {
	RootCmd.PersistentFlags().StringVarP(&verbosity, "verbosity", "v", slog.LevelWarn.String(), "Log level (debug, info, warn, error")
	RootCmd.PersistentFlags().BoolVarP(&color, "color", "c", true, "Use color in logs")
}

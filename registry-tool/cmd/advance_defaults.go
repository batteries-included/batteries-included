/*
Copyright © 2025 Elliott Clark
*/
package cmd

import (
	"fmt"
	"log/slog"
	"registry-tool/pkg/registry"

	"github.com/spf13/cobra"
)

var advanceDefaultsCmdFlags SharedRegistryFlags

var advanceDefaultsCmd = &cobra.Command{
	Use:     "advance-defaults",
	Example: "registry-tool advance-defaults <registry-file>",
	Args:    cobra.ExactArgs(1), // Ensure exactly one argument is provided
	Short:   "Update the default tags in the registry",
	Long: `After the registry has been updated with new tags, this command
will advance the default tags for each image to the highest version available in the tags list.
This is useful for ensuring that the default tag always points to the latest version.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		if len(args) < 1 {
			return fmt.Errorf("no registry file provided")
		}

		registryPath := args[0]

		reg, err := registry.Read(registryPath)
		if err != nil {
			return fmt.Errorf("failed to read registry file: %w", err)
		}

		updater := registry.NewRegistryUpdater(reg, advanceDefaultsCmdFlags.ignoredImages)
		if err := updater.UpdateDefaultTags(); err != nil {
			return fmt.Errorf("failed to advance default tags: %w", err)
		}
		if !advanceDefaultsCmdFlags.dryRun {
			err = updater.Write(registryPath)
			if err != nil {
				return fmt.Errorf("failed to write registry file: %w", err)
			}
		} else {
			slog.Info("dry run mode, no changes will be made", "file", registryPath)
		}

		return nil
	},
}

func init() {
	advanceDefaultsCmd.Flags().StringSliceVarP(&advanceDefaultsCmdFlags.ignoredImages, "ignored-images", "I", []string{"ecto/schema/test"}, "List of images to ignore")
	advanceDefaultsCmd.Flags().BoolVarP(&advanceDefaultsCmdFlags.dryRun, "dry-run", "D", false, "Perform a dry run without making changes")
	RootCmd.AddCommand(advanceDefaultsCmd)
}

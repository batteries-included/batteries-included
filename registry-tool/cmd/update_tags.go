/*
Copyright © 2025 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"fmt"

	"log/slog"
	"registry-tool/pkg/registry"

	"github.com/spf13/cobra"
)

var ignoredImages []string
var dryRun bool

var updateTagsCmd = &cobra.Command{
	Use:   "update-tags [registry-file]",
	Short: "Update the registry with new image tags",
	Long: `Update all tag lists in the registry to include the 
latest versions that match each image's configured tag pattern.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		if len(args) < 1 {
			return fmt.Errorf("no registry file provided")
		}

		registryPath := args[0]

		reg, err := registry.Read(registryPath)
		if err != nil {
			return fmt.Errorf("failed to read registry file: %w", err)
		}

		updater := registry.NewRegistryUpdater(reg, ignoredImages)

		if err := updater.UpdateTags(); err != nil {
			return fmt.Errorf("failed to update image tags: %w", err)
		}

		if !dryRun {
			err = updater.Write(registryPath)
			if err != nil {
				slog.Error("failed to write registry file", "file", registryPath, "error", err)
				return err
			}
		} else {
			slog.Info("dry run mode, no changes will be made", "file", registryPath)
		}
		return nil
	},
}

func init() {
	updateTagsCmd.Flags().StringSliceVarP(&ignoredImages, "ignored-images", "I", []string{"ecto/schema/test"}, "List of images to ignore")
	// Add Dry Run flag to the command
	updateTagsCmd.Flags().BoolVarP(&dryRun, "dry-run", "D", false, "Perform a dry run without making changes")
	RootCmd.AddCommand(updateTagsCmd)
}

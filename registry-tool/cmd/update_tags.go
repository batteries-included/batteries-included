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

var updateFlags SharedRegistryFlags

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

		updater := registry.NewRegistryUpdater(reg, updateFlags.ignoredImages)

		if err := updater.UpdateTags(); err != nil {
			return fmt.Errorf("failed to update image tags: %w", err)
		}

		if !updateFlags.dryRun {
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
	// Notice that we don't use the DefaultIgnoredImages here,
	// as we want to keep updating even while we can't upgrade some images.
	updateTagsCmd.Flags().StringSliceVarP(&updateFlags.ignoredImages, "ignored-images", "I", []string{"ecto/schema/test"}, "List of images to ignore")
	updateTagsCmd.Flags().BoolVarP(&updateFlags.dryRun, "dry-run", "D", false, "Perform a dry run without making changes")
	RootCmd.AddCommand(updateTagsCmd)
}

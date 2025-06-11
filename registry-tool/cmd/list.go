/*
Copyright © 2025 Elliott Clark
*/
package cmd

import (
	"fmt"
	"registry-tool/pkg/registry"
	"slices"

	"github.com/spf13/cobra"
)

var listIgnoredImages []string

var listCmd = &cobra.Command{
	Use:     "list",
	Example: "registry-tool list <registry-file>",
	Args:    cobra.ExactArgs(1), // Ensure exactly one argument is provided
	Short:   "List images in the registry",
	Long:    `A command to list all images in the registry, with filtering options.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		file := args[0]
		filterAdvancable, _ := cmd.Flags().GetBool("advancable")

		// if the filterAdvancable flag is set and the user hasn't provided a list
		// of ignored images, set the default ignored images
		if filterAdvancable && !cmd.Flags().Changed("ignored-images") {
			listIgnoredImages = DefaultIgnoredImages
		}

		reg, err := registry.Read(file)
		if err != nil {
			return fmt.Errorf("failed to read registry file %q: %w", file, err)
		}
		// List the images in the registry
		for _, record := range reg.Records() {
			if filterAdvancable && record.DefaultTag == record.MaxTag() {
				// If the advancable flag is set, only list
				// images where the default tag can be advanced
				continue
			}

			if slices.Contains(listIgnoredImages, record.Name) {
				continue // Skip ignored images
			}
			fmt.Printf("%s\n", record.Name)
		}
		return nil
	},
}

func init() {
	// Advancable flag means filter for images where the default tag can be advanced
	listCmd.Flags().BoolP("advancable", "a", false, "List only images where the default tag can be advanced")

	// By default we don't ignore any images, but the user can specify a list of images to ignore
	// however when the advancable flag is set, we set the default ignored images
	// to the DefaultIgnoredImages, so that we can filter out images that are not advancable
	// and the user doesn't have to specify them.
	listCmd.Flags().StringSliceVarP(&listIgnoredImages, "ignored-images", "I", []string{}, "List of images to ignore")
	RootCmd.AddCommand(listCmd)
}

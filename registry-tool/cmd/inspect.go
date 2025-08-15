/*
Copyright © 2025 Elliott Clark
*/
package cmd

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"registry-tool/pkg/registry"
	"slices"
	"time"

	"github.com/spf13/cobra"
)

// inspectCmd represents the inspect command
var inspectCmd = &cobra.Command{
	Use:     "inspect <registry-file> <image-id>",
	Example: "registry-tool inspect registry.yaml my-image",
	Args:    cobra.ExactArgs(2), // Ensure exactly two arguments are provided
	Short:   "Inspect local and remote registry information for an image",
	Long: `Inspect displays detailed information about an image including:
- Local registry information (current tags, default tag, etc.)
- Remote registry information equivalent to 'docker image inspect' for all remote tags`,
	RunE: func(cmd *cobra.Command, args []string) error {
		registryFile := args[0]
		imageId := args[1]

		reg, err := registry.Read(registryFile)
		if err != nil {
			return fmt.Errorf("failed to read registry file %q: %w", registryFile, err)
		}

		record, found := reg.Get(imageId)
		if !found {
			return fmt.Errorf("image %q not found in registry file %q", imageId, registryFile)
		}

		return inspectImage(record)
	},
}

type LocalImageInfo struct {
	Name            string   `json:"name"`
	DefaultTag      string   `json:"default_tag"`
	CurrentTags     []string `json:"current_tags"`
	BlacklistedTags []string `json:"blacklisted_tags,omitempty"`
	TagRegex        string   `json:"tag_regex,omitempty"`
	MaxTag          string   `json:"max_tag"`
}

type InspectOutput struct {
	Local  LocalImageInfo           `json:"local"`
	Remote []registry.RemoteTagInfo `json:"remote"`
}

func inspectImage(record registry.ImageRecord) error {
	// Print local information
	fmt.Println("=== LOCAL REGISTRY INFORMATION ===")
	localInfo := LocalImageInfo{
		Name:            record.Name,
		DefaultTag:      record.DefaultTag,
		CurrentTags:     record.Tags,
		BlacklistedTags: record.BlacklistedTags,
		TagRegex:        record.TagRegex,
		MaxTag:          record.MaxTag(),
	}

	localJSON, err := json.MarshalIndent(localInfo, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal local info: %w", err)
	}
	fmt.Println(string(localJSON))

	fmt.Println("\n=== REMOTE REGISTRY INFORMATION ===")

	// Get remote information for all tags
	remoteInfo, err := getRemoteTagsInfo(record)
	if err != nil {
		return fmt.Errorf("failed to get remote information: %w", err)
	}

	if len(remoteInfo) == 0 {
		fmt.Println("No remote tags found or accessible")
		return nil
	}

	// Print detailed remote information
	for _, tagInfo := range remoteInfo {
		fmt.Printf("\n--- Tag: %s ---\n", tagInfo.Tag)
		tagJSON, err := json.MarshalIndent(tagInfo, "", "  ")
		if err != nil {
			slog.Warn("failed to marshal tag info", "tag", tagInfo.Tag, "error", err)
			continue
		}
		fmt.Println(string(tagJSON))
	}

	// Also print combined output for programmatic use
	fmt.Println("\n=== COMBINED OUTPUT ===")
	output := InspectOutput{
		Local:  localInfo,
		Remote: remoteInfo,
	}

	combinedJSON, err := json.MarshalIndent(output, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal combined output: %w", err)
	}
	fmt.Println(string(combinedJSON))

	return nil
}

func getRemoteTagsInfo(record registry.ImageRecord) ([]registry.RemoteTagInfo, error) {
	// Create a remote repository with default retry settings
	remoteRepo, err := registry.NewBatteryRemoteRepositoryFromString(record.Name, 3, 1*time.Second, 500*time.Millisecond)
	if err != nil {
		return nil, fmt.Errorf("failed to create remote repository for %q: %w", record.Name, err)
	}

	// Get all available tags from remote
	remoteTags, err := remoteRepo.ListTags()
	if err != nil {
		return nil, fmt.Errorf("failed to list remote tags for %q: %w", record.Name, err)
	}

	// Filter to only the tags we're interested in (those in our local registry plus any that match our regex)
	var tagsToInspect []string

	// Add all tags from our local registry
	tagsToInspect = append(tagsToInspect, record.Tags...)

	// Add the default tag if not already included
	if !slices.Contains(tagsToInspect, record.DefaultTag) {
		tagsToInspect = append(tagsToInspect, record.DefaultTag)
	}

	// Also include any remote tags that match our filter criteria
	if record.TagRegex != "" {
		filteredTags, err := record.FilterTags(remoteTags)
		if err != nil {
			slog.Warn("failed to filter remote tags", "error", err)
		} else {
			for _, tag := range filteredTags {
				if !slices.Contains(tagsToInspect, tag) {
					tagsToInspect = append(tagsToInspect, tag)
				}
			}
		}
	}

	// Get detailed information for all tags
	return remoteRepo.GetTagsInfo(tagsToInspect)
}

func init() {
	RootCmd.AddCommand(inspectCmd)
}

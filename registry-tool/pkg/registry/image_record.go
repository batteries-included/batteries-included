package registry

import (
	"fmt"
	"regexp"
	"slices"

	"registry-tool/pkg/versions"
)

// ImageRecord represents a container image entry in the registry
type ImageRecord struct {
	Name            string   `yaml:"name"`
	DefaultTag      string   `yaml:"default_tag"`
	BlacklistedTags []string `yaml:"blacklisted_tags,omitempty"` // Tags that should be ignored
	Tags            []string `yaml:"tags"`
	TagRegex        string   `yaml:"tag_regex,omitempty"`
}

// MaxTag returns the highest version tag in the record
func (r *ImageRecord) MaxTag() string {
	if len(r.Tags) == 0 {
		return r.DefaultTag
	}

	maxTag := r.DefaultTag
	for _, tag := range r.Tags {
		if versions.Compare(tag, maxTag) > 0 {
			maxTag = tag
		}
	}
	return maxTag
}

// Validate ensures the ImageRecord has valid values
func (r *ImageRecord) Validate() error {
	if r.Name == "" {
		return fmt.Errorf("image name cannot be empty")
	}
	if r.DefaultTag == "" {
		return fmt.Errorf("default tag cannot be empty")
	}
	// Default tag must be in the tags list if tags exist
	if len(r.Tags) > 0 && !slices.Contains(r.Tags, r.DefaultTag) {
		return fmt.Errorf("default tag %q not found in tags list", r.DefaultTag)
	}

	// No tag should ever be in the blacklisted tags
	for _, tag := range r.BlacklistedTags {
		if tag == r.DefaultTag {
			return fmt.Errorf("default tag %q cannot be in blacklisted tags", r.DefaultTag)
		}
		if slices.Contains(r.Tags, tag) {
			return fmt.Errorf("tag %q cannot be in both tags and blacklisted tags", tag)
		}
	}

	// Validate tag regex if provided
	if r.TagRegex != "" {
		_, err := regexp.Compile(r.TagRegex)
		if err != nil {
			return fmt.Errorf("invalid tag regex %q: %w", r.TagRegex, err)
		}
	}

	// Validate default tag is in tags list if tags exist
	if len(r.Tags) > 0 {
		found := false
		for _, tag := range r.Tags {
			if tag == r.DefaultTag {
				found = true
				break
			}
		}
		if !found {
			return fmt.Errorf("default tag %q not found in tags list", r.DefaultTag)
		}
	}

	return nil
}

func (r *ImageRecord) FilterTags(tags []string) ([]string, error) {
	if r.TagRegex == "" {
		return []string{}, nil // No regex provided, return empty slice
	}

	re, err := regexp.Compile(r.TagRegex)
	if err != nil {
		return nil, fmt.Errorf("invalid tag regex %q: %w", r.TagRegex, err)
	}

	var filtered []string
	// Keep only tags that match the regex and are greater than or equal to the default tag
	// don't include blacklisted tags
	for _, tag := range tags {
		if re.MatchString(tag) && !slices.Contains(r.BlacklistedTags, tag) && versions.Compare(tag, r.DefaultTag) >= 0 {
			filtered = append(filtered, tag)
		}
	}
	versions.Sort(filtered)

	return filtered, nil
}

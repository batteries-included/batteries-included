package registry

import (
	"fmt"
	"log/slog"
	"registry-tool/pkg/versions"
	"slices"

	"github.com/google/go-containerregistry/pkg/authn"
	"github.com/google/go-containerregistry/pkg/name"
	"github.com/google/go-containerregistry/pkg/v1/remote"
)

type RegistryUpdater struct {
	registry    Registry
	ignoredList []string
	keychain    authn.Keychain
	changed     bool
}

func NewRegistryUpdater(registry Registry, ignoredImages []string) *RegistryUpdater {
	return &RegistryUpdater{
		registry:    registry,
		ignoredList: ignoredImages,
		keychain:    authn.DefaultKeychain,
		changed:     false,
	}
}

func (u *RegistryUpdater) Write(path string) error {
	if !u.changed {
		slog.Info("no changes to write")
		return nil
	}

	if err := u.registry.Write(path); err != nil {
		slog.Error("failed to write registry file", "file", path, "error", err)
		return fmt.Errorf("failed to write registry file %q: %w", path, err)
	}
	slog.Info("registry updated", "file", path)
	return nil
}

func (u *RegistryUpdater) UpdateTags() error {
	for name, record := range u.registry.Records() {
		if err := u.updateImageTags(name, record); err != nil {
			slog.Error("failed to update image tags", "image", name, "error", err)
			return fmt.Errorf("failed to update tags for image %q: %w", name, err)
		}
	}
	return nil
}

// updateImageTags fetches and updates tags for a single image
func (u *RegistryUpdater) updateImageTags(key string, record ImageRecord) error {
	if slices.Contains(u.ignoredList, record.Name) {
		slog.Info("ignoring image", "name", record.Name)
		return nil
	}

	ref, err := name.ParseReference(record.Name)
	if err != nil {
		return fmt.Errorf("failed to parse image reference %q: %w", record.Name, err)
	}

	tags, err := remote.List(ref.Context(), remote.WithAuthFromKeychain(u.keychain))
	if err != nil {
		return fmt.Errorf("failed to list tags for %q: %w", record.Name, err)
	}

	// Filter and sort tags
	validTags, err := record.FilterTags(tags)
	if err != nil {
		slog.Error("failed to filter tags", "image", record.Name, "error", err)
		return err
	}

	if len(validTags) == 0 {
		slog.Warn("no valid tags found", "image", record.Name)
		return nil
	}

	newTags := versions.MergeSortedUnique(record.Tags, validTags)
	// If the new tags are the same as the existing ones, skip updating
	if slices.Equal(newTags, record.Tags) {
		return nil
	}

	slog.Info("updating tags for image", "name", record.Name, "old_tags", record.Tags, "new_tags", newTags)

	// Update the record
	record.Tags = newTags
	return u.registry.Set(key, record)
}

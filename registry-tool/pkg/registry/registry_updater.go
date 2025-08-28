package registry

import (
	"fmt"
	"log/slog"
	"math/rand"
	"registry-tool/pkg/versions"
	"slices"
	"time"

	"github.com/google/go-containerregistry/pkg/authn"
	"github.com/google/go-containerregistry/pkg/name"
)

type RegistryUpdater struct {
	registry    Registry
	ignoredList []string
	keychain    authn.Keychain
	changed     bool
	delay       time.Duration
	jitter      time.Duration
	maxFailures int
}

func NewRegistryUpdater(registry Registry, ignoredImages []string, maxFailures int) *RegistryUpdater {
	return &RegistryUpdater{
		registry:    registry,
		ignoredList: ignoredImages,
		keychain:    authn.DefaultKeychain,
		changed:     false,
		delay:       0,
		jitter:      0,
		maxFailures: maxFailures,
	}
}

func NewRegistryUpdaterWithDelay(registry Registry, ignoredImages []string, delay, jitter time.Duration, maxFailures int) *RegistryUpdater {
	return &RegistryUpdater{
		registry:    registry,
		ignoredList: ignoredImages,
		keychain:    authn.DefaultKeychain,
		changed:     false,
		delay:       delay,
		jitter:      jitter,
		maxFailures: maxFailures,
	}
}

func (u *RegistryUpdater) Write(path string) error {
	if !u.changed {
		slog.Info("no changes to write")
		// Return an error when there's no changes to
		// show that the pr process should be skipped.
		return fmt.Errorf("no changes to write: %w", ErrNoChanges)
	}

	if err := u.registry.Write(path); err != nil {
		slog.Error("failed to write registry file", "file", path, "error", err)
		return fmt.Errorf("failed to write registry file %q: %w", path, err)
	}
	slog.Info("registry updated", "file", path)
	return nil
}

// calculateDelay returns the delay duration with optional jitter applied
func (u *RegistryUpdater) calculateDelay() time.Duration {
	if u.delay <= 0 {
		return 0
	}

	baseDelay := u.delay
	if u.jitter > 0 {
		// Add random jitter between -jitter and +jitter
		jitterAmount := time.Duration(rand.Int63n(int64(u.jitter*2))) - u.jitter
		baseDelay += jitterAmount
		// Ensure the delay is never negative
		if baseDelay < 0 {
			baseDelay = 0
		}
	}

	return baseDelay
}

func (u *RegistryUpdater) UpdateTags() error {
	imageCount := len(u.registry.Records())
	currentImage := 0
	failureCount := 0

	for name, record := range u.registry.Records() {
		currentImage++

		if err := u.updateImageTags(name, record); err != nil {
			failureCount++
			slog.Error("failed to update image tags", "image", name, "error", err, "failures", failureCount, "max_failures", u.maxFailures)

			if failureCount > u.maxFailures {
				return fmt.Errorf("too many failures (%d) exceeded maximum allowed (%d), last error for image %q: %w", failureCount, u.maxFailures, name, err)
			}

			// Continue processing other images even after a failure
			slog.Warn("continuing despite failure", "image", name, "failures", failureCount, "max_failures", u.maxFailures)
		}
		delay := u.calculateDelay()
		if delay > 0 {
			slog.Debug("applying delay before processing next image",
				"name", name,
				"image", record.Name,
				"delay", delay.String(),
				"progress", fmt.Sprintf("%d/%d", currentImage, imageCount))
			time.Sleep(delay)
		}
	}

	if failureCount > 0 {
		slog.Info("completed with some failures", "total_failures", failureCount, "max_failures", u.maxFailures)
	}

	return nil
}

func (u *RegistryUpdater) UpdateDefaultTags() error {
	for name, record := range u.registry.Records() {
		if slices.Contains(u.ignoredList, record.Name) {
			slog.Info("ignoring image", "name", record.Name)
			continue
		}

		maxTag := record.MaxTag()
		if maxTag == "" {
			slog.Warn("no tags found for image", "name", record.Name)
			continue
		}

		if maxTag == record.DefaultTag {
			slog.Debug("default tag already up to date", "image", record.Name, "tag", maxTag)
			continue
		}

		slog.Info("updating default tag for image", "name", record.Name, "old_tag", record.DefaultTag, "new_tag", maxTag)
		record.DefaultTag = maxTag

		if err := u.registry.Set(name, record); err != nil {
			return fmt.Errorf("failed to update default tag for %q: %w", name, err)
		}
		u.changed = true
	}
	return nil
}

// updateImageTags fetches and updates tags for a single image
func (u *RegistryUpdater) updateImageTags(key string, record ImageRecord) error {
	if slices.Contains(u.ignoredList, record.Name) {
		slog.Info("ignoring image", "name", record.Name)
		return nil
	}

	// Create a remote repository with the configured delay and jitter
	ref, err := name.ParseReference(record.Name)
	if err != nil {
		return fmt.Errorf("failed to create remote repository for %q: %w", record.Name, err)
	}
	remoteRepo := NewBatteryRemoteRepository(ref.Context(), 3, u.delay, u.jitter)

	// Set the keychain for authentication
	remoteRepo.SetKeychain(u.keychain)

	// List tags using the remote repository
	tags, err := remoteRepo.ListTags()
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
		slog.Debug("no new tags to update", "image", record.Name, "tags", newTags)
		return nil
	}

	slog.Info("updating tags for image", "name", record.Name, "old_tags", record.Tags, "new_tags", newTags)

	// Update the record
	record.Tags = newTags
	err = u.registry.Set(key, record)
	if err != nil {
		return fmt.Errorf("failed to update record for %q: %w", record.Name, err)
	}
	u.changed = true
	slog.Info("tags updated", "image", record.Name, "tags", newTags)
	return nil
}

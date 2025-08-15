package registry

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"time"

	"github.com/avast/retry-go/v4"
	"github.com/google/go-containerregistry/pkg/authn"
	"github.com/google/go-containerregistry/pkg/name"
	"github.com/google/go-containerregistry/pkg/v1/remote"
)

// BatteryRemoteRepository provides methods to interact with remote container registries
// with configurable retry logic and authentication
type BatteryRemoteRepository struct {
	repository name.Repository
	keychain   authn.Keychain
	attempts   uint
	delay      time.Duration
	jitter     time.Duration
}

// NewBatteryRemoteRepository creates a new remote repository handler
func NewBatteryRemoteRepository(repo name.Repository, attempts uint, delay, jitter time.Duration) *BatteryRemoteRepository {
	// If delay or jitter are 0 then use the defaults of 128 ms
	if delay <= 0 {
		delay = 128 * time.Millisecond
	}
	if jitter <= 0 {
		jitter = 128 * time.Millisecond
	}

	return &BatteryRemoteRepository{
		repository: repo,
		keychain:   authn.DefaultKeychain,
		attempts:   attempts,
		delay:      delay,
		jitter:     jitter,
	}
}

// NewBatteryRemoteRepositoryFromString creates a new remote repository handler from a string reference
func NewBatteryRemoteRepositoryFromString(repoName string, attempts uint, delay, jitter time.Duration) (*BatteryRemoteRepository, error) {
	ref, err := name.ParseReference(repoName)
	if err != nil {
		return nil, fmt.Errorf("failed to parse repository reference %q: %w", repoName, err)
	}

	return NewBatteryRemoteRepository(ref.Context(), attempts, delay, jitter), nil
}

// ListTags returns all tags available in the remote repository
func (b *BatteryRemoteRepository) ListTags() ([]string, error) {
	var tags []string

	err := retry.Do(
		func() error {
			var listErr error
			tags, listErr = remote.List(b.repository, remote.WithAuthFromKeychain(b.keychain))
			if listErr != nil {
				slog.Warn("failed to list tags, retrying",
					"repository", b.repository.Name(),
					"error", listErr)
			}
			return listErr
		},
		retry.Attempts(b.attempts),
		retry.Delay(b.delay),
		retry.DelayType(retry.BackOffDelay),
		retry.MaxJitter(b.jitter),
	)

	if err != nil {
		return nil, fmt.Errorf("failed to list tags for repository %q after %d attempts: %w",
			b.repository.Name(), b.attempts, err)
	}

	slog.Debug("successfully listed tags",
		"repository", b.repository.Name(),
		"tag_count", len(tags))

	return tags, nil
}

// GetRepository returns the underlying repository reference
func (b *BatteryRemoteRepository) GetRepository() name.Repository {
	return b.repository
}

// GetRepositoryName returns the repository name as a string
func (b *BatteryRemoteRepository) GetRepositoryName() string {
	return b.repository.Name()
}

// SetKeychain allows setting a custom keychain for authentication
func (b *BatteryRemoteRepository) SetKeychain(keychain authn.Keychain) {
	b.keychain = keychain
}

// GetImage returns a remote image reference for a specific tag
func (b *BatteryRemoteRepository) GetImage(tag string) (name.Reference, error) {
	return name.ParseReference(fmt.Sprintf("%s:%s", b.repository.Name(), tag))
}

// RemoteTagInfo contains detailed information about a remote tag
type RemoteTagInfo struct {
	Tag      string                 `json:"tag"`
	Digest   string                 `json:"digest"`
	Manifest map[string]interface{} `json:"manifest"`
	Config   map[string]interface{} `json:"config"`
}

// GetTagInfo returns detailed information about a specific tag
func (b *BatteryRemoteRepository) GetTagInfo(tag string) (*RemoteTagInfo, error) {
	tagRef, err := b.GetImage(tag)
	if err != nil {
		return nil, fmt.Errorf("failed to parse tag reference: %w", err)
	}

	var tagInfo *RemoteTagInfo
	err = retry.Do(
		func() error {
			// Get image manifest
			image, err := remote.Image(tagRef, remote.WithAuthFromKeychain(b.keychain))
			if err != nil {
				slog.Warn("failed to get image for tag, retrying", "tag", tag, "error", err)
				return err
			}

			// Get manifest
			manifest, err := image.Manifest()
			if err != nil {
				slog.Warn("failed to get manifest for tag, retrying", "tag", tag, "error", err)
				return err
			}

			// Get config
			config, err := image.ConfigFile()
			if err != nil {
				slog.Warn("failed to get config for tag, retrying", "tag", tag, "error", err)
				return err
			}

			// Get digest
			digest, err := image.Digest()
			if err != nil {
				slog.Warn("failed to get digest for tag, retrying", "tag", tag, "error", err)
				return err
			}

			// Convert manifest and config to maps for JSON output
			manifestMap := make(map[string]interface{})
			configMap := make(map[string]interface{})

			manifestJSON, _ := json.Marshal(manifest)
			configJSON, _ := json.Marshal(config)

			json.Unmarshal(manifestJSON, &manifestMap)
			json.Unmarshal(configJSON, &configMap)

			tagInfo = &RemoteTagInfo{
				Tag:      tag,
				Digest:   digest.String(),
				Manifest: manifestMap,
				Config:   configMap,
			}

			return nil
		},
		retry.Attempts(b.attempts),
		retry.Delay(b.delay),
		retry.DelayType(retry.BackOffDelay),
		retry.MaxJitter(b.jitter),
	)

	if err != nil {
		return nil, fmt.Errorf("failed to get tag info for %q after %d attempts: %w", tag, b.attempts, err)
	}

	slog.Debug("retrieved remote info for tag", "tag", tag, "digest", tagInfo.Digest)
	return tagInfo, nil
}

// GetTagsInfo returns detailed information for multiple tags
func (b *BatteryRemoteRepository) GetTagsInfo(tags []string) ([]RemoteTagInfo, error) {
	var remoteInfo []RemoteTagInfo

	// Get all available tags from remote to validate
	remoteTags, err := b.ListTags()
	if err != nil {
		return nil, fmt.Errorf("failed to list remote tags: %w", err)
	}

	for _, tag := range tags {
		// Check if this tag exists in remote
		found := false
		for _, remoteTag := range remoteTags {
			if remoteTag == tag {
				found = true
				break
			}
		}

		if !found {
			slog.Warn("tag not found in remote registry", "tag", tag, "repository", b.repository.Name())
			continue
		}

		tagInfo, err := b.GetTagInfo(tag)
		if err != nil {
			slog.Warn("failed to get tag info", "tag", tag, "error", err)
			continue
		}

		remoteInfo = append(remoteInfo, *tagInfo)
	}

	return remoteInfo, nil
}

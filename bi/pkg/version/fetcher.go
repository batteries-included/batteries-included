package version

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"bi/pkg/jwt"
)

const (
	githubLatestURL   = "https://api.github.com/repos/batteries-included/batteries-included/releases/latest"
	stableVersionsURL = "https://home.batteriesincl.com/api/v1/stable_versions"
)

// Release represents a GitHub release
type Release struct {
	TagName string `json:"tag_name"`
}

// StableVersions represents the decoded JWT payload from stable versions API
type StableVersions struct {
	BI            string `json:"bi"`
	ControlServer string `json:"control_server"`
}

// VersionFetcher handles fetching version information from various sources
type VersionFetcher struct {
	verifier *jwt.JWTVerifier
	client   *http.Client
}

// VersionFetcherOption is a function that configures a VersionFetcher
type VersionFetcherOption func(*VersionFetcher)

// WithJWTVerifier sets the JWT verifier for the version fetcher
func WithJWTVerifier(verifier *jwt.JWTVerifier) VersionFetcherOption {
	return func(vf *VersionFetcher) {
		vf.verifier = verifier
	}
}

// WithHTTPClient sets the HTTP client for the version fetcher
func WithHTTPClient(client *http.Client) VersionFetcherOption {
	return func(vf *VersionFetcher) {
		vf.client = client
	}
}

// NewVersionFetcher creates a new VersionFetcher with the provided options
func NewVersionFetcher(options ...VersionFetcherOption) *VersionFetcher {
	// Set defaults
	vf := &VersionFetcher{
		verifier: jwt.VerifyProd(), // Default to production keys only
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}

	// Apply options
	for _, option := range options {
		option(vf)
	}

	return vf
}

// GetStableVersions fetches the complete stable versions struct using the configured JWT verifier
func (vf *VersionFetcher) GetStableVersions(ctx context.Context) (*StableVersions, error) {
	req, err := http.NewRequestWithContext(ctx, "GET", stableVersionsURL, nil)
	if err != nil {
		return nil, err
	}

	resp, err := vf.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("stable versions API returned status %d", resp.StatusCode)
	}

	responseBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %w", err)
	}

	payloadBytes, err := vf.verifier.ParseHomeBaseJWT(responseBytes)
	if err != nil {
		return nil, fmt.Errorf("failed to parse stable versions JWT: %w", err)
	}

	// Parse the stable versions struct
	var stableVersions StableVersions
	err = json.Unmarshal(payloadBytes, &stableVersions)
	if err != nil {
		return nil, fmt.Errorf("failed to parse stable versions JSON: %w", err)
	}

	return &stableVersions, nil
}

// GetLatestVersion fetches the latest version from GitHub releases
func (vf *VersionFetcher) GetLatestVersion(ctx context.Context) (string, error) {
	req, err := http.NewRequestWithContext(ctx, "GET", githubLatestURL, nil)
	if err != nil {
		return "", err
	}

	resp, err := vf.client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("GitHub API returned status %d", resp.StatusCode)
	}

	var release Release
	if err := json.NewDecoder(resp.Body).Decode(&release); err != nil {
		return "", err
	}

	return release.TagName, nil
}

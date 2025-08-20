package update

import (
	"archive/tar"
	"bi/pkg/osutil"
	"compress/gzip"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/adrg/xdg"
	"golang.org/x/mod/semver"
)

const (
	githubAPIURL = "https://api.github.com/repos/batteries-included/batteries-included/releases/tags/%s"
	binaryName   = "bi"
	archiveName  = "batteries-included"
	checksumFile = "batteries-included_%s_checksums.txt"
)

// ReleaseAsset represents a GitHub release asset
type ReleaseAsset struct {
	Name               string `json:"name"`
	BrowserDownloadURL string `json:"browser_download_url"`
}

// Release represents a GitHub release
type Release struct {
	TagName string         `json:"tag_name"`
	Assets  []ReleaseAsset `json:"assets"`
}

// InstallOptions contains options for the install operation
type InstallOptions struct {
	Version     string
	ForceUpdate bool
	ForceLink   bool
	DataHome    string
	BinHome     string
}

// Installer handles binary installation and updates
type Installer struct {
	options InstallOptions
	client  *http.Client
}

// NewInstaller creates a new installer with the given options
func NewInstaller(options InstallOptions) *Installer {
	if options.DataHome == "" {
		options.DataHome = filepath.Join(xdg.DataHome, "bi")
	}
	if options.BinHome == "" {
		// XDG doesn't define a standard BIN_HOME, so we use ~/.local/bin as fallback
		options.BinHome = filepath.Join(filepath.Dir(xdg.DataHome), "bin")
	}

	return &Installer{
		options: options,
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// Install downloads and installs the binary
func (i *Installer) Install(ctx context.Context) error {
	// Get release information
	release, err := i.getRelease(ctx)
	if err != nil {
		return fmt.Errorf("failed to get release: %w", err)
	}

	// Get system info
	osName := osutil.GetOSName()
	archName := osutil.GetArchName()

	// Find binary and checksum assets
	binaryAsset, checksumAsset, err := i.findAssets(release, osName, archName)
	if err != nil {
		return fmt.Errorf("failed to find assets: %w", err)
	}

	// Check if we should skip installation
	if !i.options.ForceUpdate {
		if i.versionExists(release.TagName) {
			return fmt.Errorf("version %s already exists (use --force-update to override)", release.TagName)
		}
	}

	// Create temporary directory
	tempDir, err := os.MkdirTemp("", "bi-install-*")
	if err != nil {
		return fmt.Errorf("failed to create temp directory: %w", err)
	}
	defer os.RemoveAll(tempDir)

	// Download checksum file
	checksumPath := filepath.Join(tempDir, checksumFile)
	if err := i.downloadFile(ctx, checksumAsset.BrowserDownloadURL, checksumPath); err != nil {
		return fmt.Errorf("failed to download checksums: %w", err)
	}

	// Download binary
	binaryArchivePath := filepath.Join(tempDir, binaryAsset.Name)
	if err := i.downloadFile(ctx, binaryAsset.BrowserDownloadURL, binaryArchivePath); err != nil {
		return fmt.Errorf("failed to download binary: %w", err)
	}

	// Verify checksum
	if err := i.verifyChecksum(binaryArchivePath, checksumPath, binaryAsset.Name); err != nil {
		return fmt.Errorf("checksum verification failed: %w", err)
	}

	// Extract binary
	binaryPath := filepath.Join(tempDir, binaryName)
	if err := i.extractBinary(binaryArchivePath, binaryPath); err != nil {
		return fmt.Errorf("failed to extract binary: %w", err)
	}

	// Install binary
	if err := i.installBinary(binaryPath, release.TagName); err != nil {
		return fmt.Errorf("failed to install binary: %w", err)
	}

	return nil
}

// getRelease fetches release information from GitHub API
func (i *Installer) getRelease(ctx context.Context) (*Release, error) {
	url := fmt.Sprintf(githubAPIURL, i.options.Version)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, err
	}

	resp, err := i.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("GitHub API returned status %d", resp.StatusCode)
	}

	var release Release
	if err := json.NewDecoder(resp.Body).Decode(&release); err != nil {
		return nil, err
	}

	return &release, nil
}

// findAssets finds the binary and checksum assets for the current platform
func (i *Installer) findAssets(release *Release, osName, archName string) (*ReleaseAsset, *ReleaseAsset, error) {
	var binaryAsset, checksumAsset *ReleaseAsset

	expectedBinaryName := fmt.Sprintf("%s_%s_%s.tar.gz", archiveName, osName, archName)
	expectedChecksumName := fmt.Sprintf(checksumFile, i.options.Version)

	for _, asset := range release.Assets {
		switch asset.Name {
		case expectedBinaryName:
			binaryAsset = &asset
		case expectedChecksumName:
			checksumAsset = &asset
		}
	}

	if binaryAsset == nil {
		return nil, nil, fmt.Errorf("binary asset not found for %s_%s", osName, archName)
	}
	if checksumAsset == nil {
		return nil, nil, fmt.Errorf("checksum asset not found")
	}

	return binaryAsset, checksumAsset, nil
}

// downloadFile downloads a file from URL to the specified path
func (i *Installer) downloadFile(ctx context.Context, url, filePath string) error {
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return err
	}

	resp, err := i.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("download failed with status %d", resp.StatusCode)
	}

	file, err := os.Create(filePath)
	if err != nil {
		return err
	}
	defer file.Close()

	_, err = io.Copy(file, resp.Body)
	return err
}

// verifyChecksum verifies the downloaded file against its checksum
func (i *Installer) verifyChecksum(filePath, checksumPath, fileName string) error {
	// Calculate file hash
	file, err := os.Open(filePath)
	if err != nil {
		return err
	}
	defer file.Close()

	hash := sha256.New()
	if _, err := io.Copy(hash, file); err != nil {
		return err
	}
	actualChecksum := hex.EncodeToString(hash.Sum(nil))

	// Read checksums file
	checksumData, err := os.ReadFile(checksumPath)
	if err != nil {
		return err
	}

	// Find expected checksum
	lines := strings.Split(string(checksumData), "\n")
	var expectedChecksum string
	for _, line := range lines {
		parts := strings.Fields(line)
		if len(parts) >= 2 && parts[1] == fileName {
			expectedChecksum = parts[0]
			break
		}
	}

	if expectedChecksum == "" {
		return fmt.Errorf("checksum not found for %s", fileName)
	}

	if actualChecksum != expectedChecksum {
		return fmt.Errorf("checksum mismatch: expected %s, got %s", expectedChecksum, actualChecksum)
	}

	return nil
}

// extractBinary extracts the binary from the tar.gz archive
func (i *Installer) extractBinary(archivePath, outputPath string) error {
	file, err := os.Open(archivePath)
	if err != nil {
		return err
	}
	defer file.Close()

	gzReader, err := gzip.NewReader(file)
	if err != nil {
		return err
	}
	defer gzReader.Close()

	tarReader := tar.NewReader(gzReader)

	for {
		header, err := tarReader.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}

		if header.Name == binaryName {
			outFile, err := os.Create(outputPath)
			if err != nil {
				return err
			}
			defer outFile.Close()

			if _, err := io.Copy(outFile, tarReader); err != nil {
				return err
			}

			// Set executable permissions
			return os.Chmod(outputPath, 0755)
		}
	}

	return fmt.Errorf("binary %s not found in archive", binaryName)
}

// installBinary installs the binary to the final location and creates symlink
func (i *Installer) installBinary(sourcePath, version string) error {
	// Create version-specific location
	if err := os.MkdirAll(i.options.DataHome, 0755); err != nil {
		return err
	}

	versionedPath := filepath.Join(i.options.DataHome, fmt.Sprintf("%s-%s", binaryName, version))

	// Copy binary to versioned location
	if err := i.copyFile(sourcePath, versionedPath); err != nil {
		return err
	}

	// Check if we should create/update symlink
	binPath := filepath.Join(i.options.BinHome, binaryName)

	shouldLink := i.options.ForceLink
	if !shouldLink {
		var err error
		shouldLink, err = i.shouldUpdateSymlink(binPath, version)
		if err != nil {
			return err
		}
	}

	if shouldLink {
		if err := os.MkdirAll(i.options.BinHome, 0755); err != nil {
			return err
		}

		// Remove existing symlink if it exists
		os.Remove(binPath)

		// Create new symlink
		if err := os.Symlink(versionedPath, binPath); err != nil {
			return err
		}
	}

	return nil
}

// copyFile copies a file from source to destination
func (i *Installer) copyFile(src, dst string) error {
	source, err := os.Open(src)
	if err != nil {
		return err
	}
	defer source.Close()

	destination, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer destination.Close()

	if _, err := io.Copy(destination, source); err != nil {
		return err
	}

	// Copy permissions
	sourceInfo, err := os.Stat(src)
	if err != nil {
		return err
	}
	return os.Chmod(dst, sourceInfo.Mode())
}

// versionExists checks if a version already exists
func (i *Installer) versionExists(version string) bool {
	versionPath := filepath.Join(i.options.DataHome, fmt.Sprintf("%s-%s", binaryName, version))
	_, err := os.Stat(versionPath)
	return err == nil
}

// shouldUpdateSymlink determines if the symlink should be updated
func (i *Installer) shouldUpdateSymlink(binPath, newVersion string) (bool, error) {
	// Check if symlink exists
	target, err := os.Readlink(binPath)
	if err != nil {
		// Symlink doesn't exist or is not a symlink, so we should create it
		return true, nil
	}

	// Extract current version from symlink target
	currentVersion := i.extractVersionFromPath(target)
	if currentVersion == "" {
		// Can't determine current version, allow update
		return true, nil
	}

	// Compare versions using semver
	if semver.IsValid(newVersion) && semver.IsValid(currentVersion) {
		return semver.Compare(newVersion, currentVersion) > 0, nil
	}

	// If semver comparison fails, do string comparison
	return newVersion > currentVersion, nil
}

// extractVersionFromPath extracts version from a path like /path/to/bi-v1.2.3
func (i *Installer) extractVersionFromPath(path string) string {
	fileName := filepath.Base(path)
	if strings.HasPrefix(fileName, binaryName+"-") {
		return strings.TrimPrefix(fileName, binaryName+"-")
	}
	return ""
}

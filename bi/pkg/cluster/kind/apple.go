package kind

import (
	"os/exec"
	"runtime"
	"strings"
)

// IsAppleVirtualizationAvailable checks if Apple's native virtualization framework is available
// This is used by tools like vfkit and can be used by container runtimes on macOS
func IsAppleVirtualizationAvailable() (bool, error) {
	// Only available on macOS
	if runtime.GOOS != "darwin" {
		return false, nil
	}

	// Check if Virtualization.framework is available (macOS 11+)
	// We can check this by looking for vfkit or checking system version
	cmd := exec.Command("sw_vers", "-productVersion")
	output, err := cmd.Output()
	if err != nil {
		return false, err
	}

	version := strings.TrimSpace(string(output))
	parts := strings.Split(version, ".")
	if len(parts) >= 1 {
		// macOS 11 (Big Sur) and later support Virtualization.framework
		majorVersion := parts[0]
		if majorVersion >= "11" {
			// Additionally check if vfkit is available (common tool using Apple Virtualization)
			if _, err := exec.LookPath("vfkit"); err == nil {
				return true, nil
			}
			// Even without vfkit, the framework is available
			return true, nil
		}
	}

	return false, nil
}
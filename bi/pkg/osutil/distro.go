package osutil

import (
	"os"
	"os/exec"
	"strings"
)

// LinuxDistribution represents the detected Linux distribution family
type LinuxDistribution int

const (
	// DistroUnknown represents an unrecognized or undetectable distribution
	DistroUnknown LinuxDistribution = iota
	// DistroDebian represents Debian-based distributions (Ubuntu, Debian)
	DistroDebian
	// DistroRHEL represents Red Hat-based distributions (RHEL, CentOS, Fedora, Amazon Linux)
	DistroRHEL
	// DistroSUSE represents SUSE-based distributions (openSUSE, SLE)
	DistroSUSE
)

// String returns the string representation of the Linux distribution
func (d LinuxDistribution) String() string {
	switch d {
	case DistroDebian:
		return "debian"
	case DistroRHEL:
		return "rhel"
	case DistroSUSE:
		return "suse"
	default:
		return "unknown"
	}
}

// DetectLinuxDistribution attempts to detect the Linux distribution family
func DetectLinuxDistribution() LinuxDistribution {
	// Try to read /etc/os-release
	if data, err := os.ReadFile("/etc/os-release"); err == nil {
		content := strings.ToLower(string(data))
		if strings.Contains(content, "ubuntu") || strings.Contains(content, "debian") {
			return DistroDebian
		}
		if strings.Contains(content, "rhel") || strings.Contains(content, "centos") ||
			strings.Contains(content, "fedora") || strings.Contains(content, "amazon") {
			return DistroRHEL
		}
		if strings.Contains(content, "opensuse") || strings.Contains(content, "sle") {
			return DistroSUSE
		}
	}

	// Try to check for package managers as fallback
	if _, err := exec.LookPath("apt"); err == nil {
		return DistroDebian
	}
	if _, err := exec.LookPath("dnf"); err == nil {
		return DistroRHEL
	}
	if _, err := exec.LookPath("yum"); err == nil {
		return DistroRHEL
	}
	if _, err := exec.LookPath("zypper"); err == nil {
		return DistroSUSE
	}

	return DistroUnknown
}

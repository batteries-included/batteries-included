package pkg

import "runtime/debug"

var Version = "unknown"

// VersionInfo contains detailed version and build information
type VersionInfo struct {
	Version   string `json:"version"`
	GoVersion string `json:"go_version"`
}

// GetVersionInfo returns structured version information
func GetVersionInfo() VersionInfo {
	versionInfo := VersionInfo{
		Version:   Version,
		GoVersion: "unknown",
	}

	// Get Go version from build info
	if info, ok := debug.ReadBuildInfo(); ok && info != nil {
		versionInfo.GoVersion = info.GoVersion
	}

	return versionInfo
}

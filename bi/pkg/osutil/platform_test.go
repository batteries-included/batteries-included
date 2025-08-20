package osutil

import (
	"runtime"
	"testing"
)

func TestGetOSName(t *testing.T) {
	osName := GetOSName()

	// Test that we get a non-empty string
	if osName == "" {
		t.Error("GetOSName() returned empty string")
	}

	// Test specific mappings
	switch runtime.GOOS {
	case "darwin":
		if osName != "Darwin" {
			t.Errorf("Expected 'Darwin' for darwin, got %s", osName)
		}
	case "linux":
		if osName != "Linux" {
			t.Errorf("Expected 'Linux' for linux, got %s", osName)
		}
	case "windows":
		if osName != "Windows" {
			t.Errorf("Expected 'Windows' for windows, got %s", osName)
		}
	default:
		// For unknown OS, should return runtime.GOOS
		if osName != runtime.GOOS {
			t.Errorf("Expected %s for unknown OS, got %s", runtime.GOOS, osName)
		}
	}
}

func TestGetArchName(t *testing.T) {
	archName := GetArchName()

	// Test that we get a non-empty string
	if archName == "" {
		t.Error("GetArchName() returned empty string")
	}

	// Test specific mappings
	switch runtime.GOARCH {
	case "amd64":
		if archName != "x86_64" {
			t.Errorf("Expected 'x86_64' for amd64, got %s", archName)
		}
	case "arm64":
		if archName != "arm64" {
			t.Errorf("Expected 'arm64' for arm64, got %s", archName)
		}
	case "386":
		if archName != "i386" {
			t.Errorf("Expected 'i386' for 386, got %s", archName)
		}
	default:
		// For unknown arch, should return runtime.GOARCH
		if archName != runtime.GOARCH {
			t.Errorf("Expected %s for unknown arch, got %s", runtime.GOARCH, archName)
		}
	}
}

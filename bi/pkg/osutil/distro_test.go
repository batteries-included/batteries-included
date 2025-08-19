package osutil

import (
	"testing"
)

func TestLinuxDistribution_String(t *testing.T) {
	tests := []struct {
		distro   LinuxDistribution
		expected string
	}{
		{DistroUnknown, "unknown"},
		{DistroDebian, "debian"},
		{DistroRHEL, "rhel"},
		{DistroSUSE, "suse"},
	}

	for _, test := range tests {
		result := test.distro.String()
		if result != test.expected {
			t.Errorf("Expected %s, got %s for distro %v", test.expected, result, test.distro)
		}
	}
}

func TestDetectLinuxDistribution(t *testing.T) {
	// This test will actually detect the real distribution on the system
	// We can't easily mock file system calls in this simple test,
	// but we can verify the function doesn't panic and returns a valid enum value
	distro := DetectLinuxDistribution()

	// Verify it's one of the valid enum values
	if distro < DistroUnknown || distro > DistroSUSE {
		t.Errorf("DetectLinuxDistribution returned invalid enum value: %v", distro)
	}

	// Verify String() method works
	distroStr := distro.String()
	if distroStr == "" {
		t.Error("String() method returned empty string")
	}

	t.Logf("Detected distribution: %s (%v)", distroStr, distro)
}

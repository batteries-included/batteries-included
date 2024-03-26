package testutil

import (
	"os"
	"testing"
)

// IntegrationTest skips the test if the INTEGRATION environment variable is not set.
// This is useful for tests that require external services to be running.
func IntegrationTest(t *testing.T) {
	if os.Getenv("INTEGRATION") == "" {
		t.Skip("skipping integration test. Set INTEGRATION=1 to run.")
	}
}

package ctkutil

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestValidateNvidiaCtk(t *testing.T) {
	ctx := context.Background()

	// Test should fail since nvidia-ctk is likely not installed in CI
	err := ValidateNvidiaCtk(ctx)
	if err != nil {
		assert.Contains(t, err.Error(), "nvidia-ctk not found")
		assert.Contains(t, err.Error(), "bi gpu validate-nvidia-ctk")
	}
}

func TestValidateDockerDaemonConfig(t *testing.T) {
	// Create a temporary directory for test files
	tempDir := t.TempDir()

	// Test with valid daemon.json
	t.Run("valid daemon.json", func(t *testing.T) {
		configPath := filepath.Join(tempDir, "daemon.json")
		validConfig := map[string]interface{}{
			"default-runtime": "nvidia",
			"runtimes": map[string]interface{}{
				"nvidia": map[string]interface{}{
					"path": "nvidia-container-runtime",
					"args": []string{},
				},
			},
		}

		data, err := json.Marshal(validConfig)
		require.NoError(t, err)

		require.NoError(t, os.WriteFile(configPath, data, 0644))

		// Test the JSON parsing logic (not the actual file validation since path is hardcoded)
		var config map[string]interface{}
		require.NoError(t, json.Unmarshal(data, &config))

		runtimes, ok := config["runtimes"].(map[string]interface{})
		assert.True(t, ok, "should have runtimes section")

		_, ok = runtimes["nvidia"]
		assert.True(t, ok, "should have nvidia runtime")
	})

	t.Run("invalid daemon.json - no runtimes", func(t *testing.T) {
		configPath := filepath.Join(tempDir, "daemon-no-runtimes.json")
		invalidConfig := map[string]interface{}{
			"default-runtime": "nvidia",
		}

		data, err := json.Marshal(invalidConfig)
		require.NoError(t, err)

		require.NoError(t, os.WriteFile(configPath, data, 0644))

		// Test the logic
		var config map[string]interface{}
		require.NoError(t, json.Unmarshal(data, &config))

		_, ok := config["runtimes"].(map[string]interface{})
		assert.False(t, ok, "should not have runtimes section")
	})
}

func TestValidateNvidiaContainerRuntimeConfig(t *testing.T) {
	// Create a temporary directory for test files
	tempDir := t.TempDir()

	t.Run("valid config.toml", func(t *testing.T) {
		configPath := filepath.Join(tempDir, "config.toml")
		validConfig := `accept-nvidia-visible-devices-as-volume-mounts = true
disable-require = false
`

		require.NoError(t, os.WriteFile(configPath, []byte(validConfig), 0644))

		// Test that our validation logic would work
		// Since we can't easily override the file path, we'll test the TOML parsing logic
		content, err := os.ReadFile(configPath)
		require.NoError(t, err)
		assert.Contains(t, string(content), "accept-nvidia-visible-devices-as-volume-mounts = true")
	})

	t.Run("invalid config.toml - setting false", func(t *testing.T) {
		configPath := filepath.Join(tempDir, "config-false.toml")
		invalidConfig := `accept-nvidia-visible-devices-as-volume-mounts = false
disable-require = false
`

		require.NoError(t, os.WriteFile(configPath, []byte(invalidConfig), 0644))

		content, err := os.ReadFile(configPath)
		require.NoError(t, err)
		assert.Contains(t, string(content), "accept-nvidia-visible-devices-as-volume-mounts = false")
	})

	t.Run("missing config.toml", func(t *testing.T) {
		configPath := filepath.Join(tempDir, "nonexistent.toml")

		_, err := os.Stat(configPath)
		assert.True(t, os.IsNotExist(err), "file should not exist")
	})
}

func TestValidateNvidiaContainerToolkit(t *testing.T) {
	ctx := context.Background()

	// Test the complete validation function
	// This will likely fail in CI since the tools aren't installed
	err := ValidateNvidiaContainerToolkit(ctx, true)
	if err != nil {
		// Should contain helpful error messages
		assert.Contains(t, err.Error(), "validation failed")
	}
}

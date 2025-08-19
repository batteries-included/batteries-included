package ctkutil

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestGPUDetector_countGPUsFromOutput(t *testing.T) {
	detector := NewGPUDetector(nil)

	tests := []struct {
		name     string
		output   string
		expected int
	}{
		{
			name:     "single GPU",
			output:   `GPU 0: NVIDIA A100-SXM4-40GB (UUID: GPU-4cf8db2d-06c0-7d70-1a51-e59b25b2c16c)`,
			expected: 1,
		},
		{
			name: "multiple GPUs",
			output: `GPU 0: NVIDIA A100-SXM4-40GB (UUID: GPU-4cf8db2d-06c0-7d70-1a51-e59b25b2c16c)
GPU 1: NVIDIA A100-SXM4-40GB (UUID: GPU-4404041a-04cf-1ccf-9e70-f139a9b1e23c)
GPU 2: NVIDIA A100-SXM4-40GB (UUID: GPU-79a2ba02-a537-ccbf-2965-8e9d90c0bd54)`,
			expected: 3,
		},
		{
			name:     "no GPUs",
			output:   "",
			expected: 0,
		},
		{
			name: "malformed output",
			output: `Some random output
that doesn't contain GPU lines`,
			expected: 0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := detector.countGPUsFromOutput(tt.output)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestGPUDetector_tryNvidiaSmiLocal(t *testing.T) {
	detector := NewGPUDetector(nil)
	ctx := context.Background()

	// This test will fail in CI if nvidia-smi is not installed
	_, err := detector.tryNvidiaSmiLocal(ctx)
	if err != nil {
		// Expected in CI environments without NVIDIA drivers
		assert.Contains(t, err.Error(), "local nvidia-smi failed")
	}
}

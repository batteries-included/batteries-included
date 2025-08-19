package ctkutil

import (
	"context"
	"encoding/json"
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

func TestGPUDetector_runNvidiaSmiLocal(t *testing.T) {
	detector := NewGPUDetector(nil)
	ctx := context.Background()

	// This test will fail in CI if nvidia-smi is not installed
	_, err := detector.runNvidiaSmiLocal(ctx, "-L")
	if err != nil {
		// Expected in CI environments without NVIDIA drivers
		assert.Contains(t, err.Error(), "local nvidia-smi failed")
	}
}

func TestGPUDetector_runNvidiaSmi(t *testing.T) {
	detector := NewGPUDetector(nil)
	ctx := context.Background()

	// Test the unified method with list GPUs
	_, err := detector.runNvidiaSmi(ctx, "-L")
	if err != nil {
		// Expected in CI environments without NVIDIA drivers
		assert.Contains(t, err.Error(), "failed to run nvidia-smi")
	}
}

func TestGPUDetector_parseGPUInfoFromCSV(t *testing.T) {
	detector := NewGPUDetector(nil)

	tests := []struct {
		name        string
		csvOutput   string
		expected    []GPUInfo
		expectError bool
	}{
		{
			name:      "single GPU valid output",
			csvOutput: "0, NVIDIA GeForce RTX 4090, GPU-fb471c4c-3eb3-b596-1211-f14110227bf8, 00000000:01:00.0, 550.163.01, 24564, 22687, 1479, 22, 13, 41, 30.18, 1080, 810",
			expected: []GPUInfo{
				{
					Index:          0,
					Name:           "NVIDIA GeForce RTX 4090",
					UUID:           "GPU-fb471c4c-3eb3-b596-1211-f14110227bf8",
					PCIBusID:       "00000000:01:00.0",
					DriverVersion:  "550.163.01",
					MemoryTotal:    24564,
					MemoryFree:     22687,
					MemoryUsed:     1479,
					UtilizationGPU: 22,
					UtilizationMem: 13,
					Temperature:    41,
					PowerDraw:      30.18,
					ClockGraphics:  1080,
					ClockMemory:    810,
				},
			},
			expectError: false,
		},
		{
			name: "multiple GPUs valid output",
			csvOutput: `0, NVIDIA A100-SXM4-40GB, GPU-4cf8db2d-06c0-7d70-1a51-e59b25b2c16c, 00000000:07:00.0, 550.163.01, 40960, 40000, 960, 15, 8, 35, 120.5, 1200, 1215
1, NVIDIA A100-SXM4-40GB, GPU-4404041a-04cf-1ccf-9e70-f139a9b1e23c, 00000000:0A:00.0, 550.163.01, 40960, 39500, 1460, 25, 12, 38, 135.2, 1300, 1215`,
			expected: []GPUInfo{
				{
					Index:          0,
					Name:           "NVIDIA A100-SXM4-40GB",
					UUID:           "GPU-4cf8db2d-06c0-7d70-1a51-e59b25b2c16c",
					PCIBusID:       "00000000:07:00.0",
					DriverVersion:  "550.163.01",
					MemoryTotal:    40960,
					MemoryFree:     40000,
					MemoryUsed:     960,
					UtilizationGPU: 15,
					UtilizationMem: 8,
					Temperature:    35,
					PowerDraw:      120.5,
					ClockGraphics:  1200,
					ClockMemory:    1215,
				},
				{
					Index:          1,
					Name:           "NVIDIA A100-SXM4-40GB",
					UUID:           "GPU-4404041a-04cf-1ccf-9e70-f139a9b1e23c",
					PCIBusID:       "00000000:0A:00.0",
					DriverVersion:  "550.163.01",
					MemoryTotal:    40960,
					MemoryFree:     39500,
					MemoryUsed:     1460,
					UtilizationGPU: 25,
					UtilizationMem: 12,
					Temperature:    38,
					PowerDraw:      135.2,
					ClockGraphics:  1300,
					ClockMemory:    1215,
				},
			},
			expectError: false,
		},
		{
			name:        "empty output",
			csvOutput:   "",
			expected:    []GPUInfo{},
			expectError: false,
		},
		{
			name:        "insufficient fields",
			csvOutput:   "0, NVIDIA GeForce RTX 4090, GPU-fb471c4c-3eb3-b596-1211-f14110227bf8",
			expected:    nil,
			expectError: true,
		},
		{
			name:        "invalid integer field",
			csvOutput:   "invalid, NVIDIA GeForce RTX 4090, GPU-fb471c4c-3eb3-b596-1211-f14110227bf8, 00000000:01:00.0, 550.163.01, 24564, 22687, 1479, 22, 13, 41, 30.18, 1080, 810",
			expected:    nil,
			expectError: true,
		},
		{
			name:        "invalid float field",
			csvOutput:   "0, NVIDIA GeForce RTX 4090, GPU-fb471c4c-3eb3-b596-1211-f14110227bf8, 00000000:01:00.0, 550.163.01, 24564, 22687, 1479, 22, 13, 41, invalid_float, 1080, 810",
			expected:    nil,
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := detector.parseGPUInfoFromCSV(tt.csvOutput)

			if tt.expectError {
				assert.Error(t, err)
				assert.Nil(t, result)
			} else {
				assert.NoError(t, err)
				assert.Equal(t, tt.expected, result)
			}
		})
	}
}

func TestGPUInfo_JSONSerialization(t *testing.T) {
	gpu := GPUInfo{
		Index:          0,
		Name:           "NVIDIA GeForce RTX 4090",
		UUID:           "GPU-fb471c4c-3eb3-b596-1211-f14110227bf8",
		PCIBusID:       "00000000:01:00.0",
		DriverVersion:  "550.163.01",
		MemoryTotal:    24564,
		MemoryFree:     22687,
		MemoryUsed:     1479,
		UtilizationGPU: 22,
		UtilizationMem: 13,
		Temperature:    41,
		PowerDraw:      30.18,
		ClockGraphics:  1080,
		ClockMemory:    810,
	}

	// Test JSON marshaling
	jsonData, err := json.Marshal(gpu)
	assert.NoError(t, err)
	assert.Contains(t, string(jsonData), `"index":0`)
	assert.Contains(t, string(jsonData), `"name":"NVIDIA GeForce RTX 4090"`)
	assert.Contains(t, string(jsonData), `"power_draw_watts":30.18`)

	// Test JSON unmarshaling
	var unmarshaledGPU GPUInfo
	err = json.Unmarshal(jsonData, &unmarshaledGPU)
	assert.NoError(t, err)
	assert.Equal(t, gpu, unmarshaledGPU)
}

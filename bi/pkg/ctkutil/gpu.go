package ctkutil

import (
	"context"
	"fmt"
	"io"
	"os/exec"
	"strconv"
	"strings"

	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/client"
)

const ubuntuImage = "ubuntu:24.04"

// GPUInfo contains detailed information about a GPU
type GPUInfo struct {
	Index          int     `json:"index"`
	Name           string  `json:"name"`
	UUID           string  `json:"uuid"`
	PCIBusID       string  `json:"pci_bus_id"`
	DriverVersion  string  `json:"driver_version"`
	MemoryTotal    int     `json:"memory_total_mb"`
	MemoryFree     int     `json:"memory_free_mb"`
	MemoryUsed     int     `json:"memory_used_mb"`
	UtilizationGPU int     `json:"utilization_gpu_percent"`
	UtilizationMem int     `json:"utilization_memory_percent"`
	Temperature    int     `json:"temperature_celsius"`
	PowerDraw      float64 `json:"power_draw_watts"`
	ClockGraphics  int     `json:"clock_graphics_mhz"`
	ClockMemory    int     `json:"clock_memory_mhz"`
}

// GPUDetector provides methods to detect NVIDIA GPUs on the host
type GPUDetector struct {
	dockerClient *client.Client
}

// NewGPUDetector creates a new GPU detector with optional Docker client
func NewGPUDetector(dockerClient *client.Client) *GPUDetector {
	return &GPUDetector{
		dockerClient: dockerClient,
	}
}

// DetectGPUs attempts to detect NVIDIA GPUs using various fallback methods
// Returns the number of GPUs found and any error encountered
func (d *GPUDetector) DetectGPUs(ctx context.Context) (int, error) {
	// Use the unified method with listing arguments
	output, err := d.runNvidiaSmi(ctx, "-L")
	if err != nil {
		return 0, fmt.Errorf("failed to detect GPUs: %w", err)
	}

	// Count GPUs from nvidia-smi output
	gpuCount := d.countGPUsFromOutput(output)
	return gpuCount, nil
}

// DetectGPUsInContainer runs nvidia-smi in a container to detect GPUs.
// It specifically uses the volume mount method if useVolumeMount is true.
func (d *GPUDetector) DetectGPUsInContainer(ctx context.Context) (int, error) {
	if d.dockerClient == nil {
		return 0, fmt.Errorf("docker client is not available for container validation")
	}

	var output string
	var err error

	args := []string{"-L"} // We just need to list GPUs

	output, err = d.runNvidiaSmiContainer(ctx, false, true, args...)

	if err != nil {
		return 0, fmt.Errorf("failed to run nvidia-smi in container: %w", err)
	}

	gpuCount := d.countGPUsFromOutput(output)
	return gpuCount, nil
}

// DetectGPUInfo retrieves detailed information about local NVIDIA GPUs
func (d *GPUDetector) DetectGPUInfo(ctx context.Context) ([]GPUInfo, error) {
	// Define the query fields we want to retrieve
	queryFields := []string{
		"index",
		"name",
		"uuid",
		"pci.bus_id",
		"driver_version",
		"memory.total",
		"memory.free",
		"memory.used",
		"utilization.gpu",
		"utilization.memory",
		"temperature.gpu",
		"power.draw",
		"clocks.current.graphics",
		"clocks.current.memory",
	}

	// Create the query string
	query := strings.Join(queryFields, ",")
	queryArgs := []string{"--query-gpu=" + query, "--format=csv,noheader,nounits"}

	// Get GPU information using the unified nvidia-smi method
	output, err := d.runNvidiaSmi(ctx, queryArgs...)
	if err != nil {
		return nil, fmt.Errorf("failed to query GPU information: %w", err)
	}

	// Parse the CSV output into GPUInfo structs
	gpus, err := d.parseGPUInfoFromCSV(output)
	if err != nil {
		return nil, fmt.Errorf("failed to parse GPU information: %w", err)
	}

	return gpus, nil
}

// runNvidiaSmi runs nvidia-smi with the specified arguments using various fallback methods
func (d *GPUDetector) runNvidiaSmi(ctx context.Context, args ...string) (string, error) {
	// Try to run nvidia-smi locally first
	output, err := d.runNvidiaSmiLocal(ctx, args...)
	if err != nil {
		// Fallback to running nvidia-smi in Docker container
		output, err = d.runNvidiaSmiDocker(ctx, args...)
		if err != nil {
			return "", fmt.Errorf("failed to run nvidia-smi: %w", err)
		}
	}
	return output, nil
}

// runNvidiaSmiLocal runs nvidia-smi locally on the host
func (d *GPUDetector) runNvidiaSmiLocal(ctx context.Context, args ...string) (string, error) {
	cmd := exec.CommandContext(ctx, "nvidia-smi")
	cmd.Args = append(cmd.Args, args...)
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("local nvidia-smi failed: %w", err)
	}
	return string(output), nil
}

// runNvidiaSmiDocker runs nvidia-smi inside a Docker container
func (d *GPUDetector) runNvidiaSmiDocker(ctx context.Context, args ...string) (string, error) {
	if d.dockerClient == nil {
		// Fallback to command execution if Docker client is not available
		return d.runNvidiaSmiDockerCommand(ctx, args...)
	}

	// Try with nvidia runtime first
	output, err := d.runNvidiaSmiContainer(ctx, true, false, args...)
	if err != nil {
		// Fallback to volume mount approach
		output, err = d.runNvidiaSmiContainer(ctx, false, true, args...)
		if err != nil {
			return "", fmt.Errorf("docker nvidia-smi failed: %w", err)
		}
	}
	return output, nil
}

// runNvidiaSmiDockerCommand is a fallback function that uses command execution
func (d *GPUDetector) runNvidiaSmiDockerCommand(ctx context.Context, args ...string) (string, error) {
	// Try with nvidia runtime first
	baseCmd := []string{"docker", "run", "--rm", "--runtime=nvidia",
		"-e", "NVIDIA_VISIBLE_DEVICES=all", ubuntuImage, "nvidia-smi"}
	cmd := exec.CommandContext(ctx, baseCmd[0], append(baseCmd[1:], args...)...)

	output, err := cmd.Output()
	if err != nil {
		// Fallback to volume mount approach
		baseCmd = []string{"docker", "run", "--rm",
			"-v", "/dev/null:/var/run/nvidia-container-devices/all",
			ubuntuImage, "nvidia-smi"}
		cmd = exec.CommandContext(ctx, baseCmd[0], append(baseCmd[1:], args...)...)

		output, err = cmd.Output()
		if err != nil {
			return "", fmt.Errorf("docker nvidia-smi command failed: %w", err)
		}
	}
	return string(output), nil
}

// runNvidiaSmiContainer runs nvidia-smi in a Docker container using the Docker client API
func (d *GPUDetector) runNvidiaSmiContainer(ctx context.Context, useNvidiaRuntime, useVolumeMount bool, args ...string) (string, error) {
	var hostConfig *container.HostConfig

	if useNvidiaRuntime {
		hostConfig = &container.HostConfig{
			AutoRemove: true,
			Runtime:    "nvidia",
		}
	} else if useVolumeMount {
		hostConfig = &container.HostConfig{
			AutoRemove: true,
			Binds: []string{
				"/dev/null:/var/run/nvidia-container-devices/all",
			},
		}
	} else {
		return "", fmt.Errorf("invalid container configuration")
	}

	// Container configuration
	cmdArgs := append([]string{"nvidia-smi"}, args...)
	containerConfig := &container.Config{
		Image: ubuntuImage,
		Cmd:   cmdArgs,
	}

	if useNvidiaRuntime {
		containerConfig.Env = []string{"NVIDIA_VISIBLE_DEVICES=all"}
	}

	// Create container
	resp, err := d.dockerClient.ContainerCreate(ctx, containerConfig, hostConfig, nil, nil, "")
	if err != nil {
		return "", fmt.Errorf("failed to create container: %w", err)
	}

	// Start container
	if err := d.dockerClient.ContainerStart(ctx, resp.ID, container.StartOptions{}); err != nil {
		return "", fmt.Errorf("failed to start container: %w", err)
	}

	// Wait for container to finish
	statusCh, errCh := d.dockerClient.ContainerWait(ctx, resp.ID, container.WaitConditionNotRunning)
	select {
	case err := <-errCh:
		if err != nil {
			return "", fmt.Errorf("error waiting for container: %w", err)
		}
	case status := <-statusCh:
		if status.StatusCode != 0 {
			// Get logs for error details
			logs, _ := d.dockerClient.ContainerLogs(ctx, resp.ID, container.LogsOptions{
				ShowStdout: true,
				ShowStderr: true,
			})
			if logs != nil {
				logData, _ := io.ReadAll(logs)
				logs.Close()
				return "", fmt.Errorf("container exited with code %d: %s", status.StatusCode, string(logData))
			}
			return "", fmt.Errorf("container exited with code %d", status.StatusCode)
		}
	}

	// Get container logs (output)
	logs, err := d.dockerClient.ContainerLogs(ctx, resp.ID, container.LogsOptions{
		ShowStdout: true,
		ShowStderr: false,
	})
	if err != nil {
		return "", fmt.Errorf("failed to get container logs: %w", err)
	}
	defer logs.Close()

	logData, err := io.ReadAll(logs)
	if err != nil {
		return "", fmt.Errorf("failed to read container logs: %w", err)
	}

	// Strip Docker log headers. Docker logs have 8-byte headers for each line:
	// 1 byte stream type (1=stdout, 2=stderr), 3 bytes padding, 4 bytes size
	cleanOutput := stripDockerLogHeaders(logData)

	return cleanOutput, nil
}

// countGPUsFromOutput parses nvidia-smi output and counts the number of GPUs
func (d *GPUDetector) countGPUsFromOutput(output string) int {
	lines := strings.Split(strings.TrimSpace(output), "\n")
	gpuCount := 0
	for _, line := range lines {
		if strings.HasPrefix(line, "GPU ") && strings.Contains(line, ":") {
			gpuCount++
		}
	}
	return gpuCount
}

// parseGPUInfoFromCSV parses the CSV output from nvidia-smi into GPUInfo structs
func (d *GPUDetector) parseGPUInfoFromCSV(csvOutput string) ([]GPUInfo, error) {
	lines := strings.Split(strings.TrimSpace(csvOutput), "\n")
	var gpus []GPUInfo

	// Handle empty output
	if len(lines) == 1 && strings.TrimSpace(lines[0]) == "" {
		return []GPUInfo{}, nil
	}

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		// Split CSV fields
		fields := strings.Split(line, ",")
		if len(fields) != 14 {
			return nil, fmt.Errorf("unexpected number of fields in CSV line: %d, expected 14", len(fields))
		}

		// Trim spaces from all fields
		for i := range fields {
			fields[i] = strings.TrimSpace(fields[i])
		}

		// Parse fields into GPUInfo struct
		gpu := GPUInfo{}
		var err error

		// Parse index
		gpu.Index, err = strconv.Atoi(fields[0])
		if err != nil {
			return nil, fmt.Errorf("failed to parse GPU index: %w", err)
		}

		// String fields
		gpu.Name = fields[1]
		gpu.UUID = fields[2]
		gpu.PCIBusID = fields[3]
		gpu.DriverVersion = fields[4]

		// Parse memory fields (in MB)
		gpu.MemoryTotal, err = strconv.Atoi(fields[5])
		if err != nil {
			return nil, fmt.Errorf("failed to parse memory total: %w", err)
		}

		gpu.MemoryFree, err = strconv.Atoi(fields[6])
		if err != nil {
			return nil, fmt.Errorf("failed to parse memory free: %w", err)
		}

		gpu.MemoryUsed, err = strconv.Atoi(fields[7])
		if err != nil {
			return nil, fmt.Errorf("failed to parse memory used: %w", err)
		}

		// Parse utilization fields (in %)
		gpu.UtilizationGPU, err = strconv.Atoi(fields[8])
		if err != nil {
			return nil, fmt.Errorf("failed to parse GPU utilization: %w", err)
		}

		gpu.UtilizationMem, err = strconv.Atoi(fields[9])
		if err != nil {
			return nil, fmt.Errorf("failed to parse memory utilization: %w", err)
		}

		// Parse temperature (in °C)
		gpu.Temperature, err = strconv.Atoi(fields[10])
		if err != nil {
			return nil, fmt.Errorf("failed to parse temperature: %w", err)
		}

		// Parse power draw (in watts)
		gpu.PowerDraw, err = strconv.ParseFloat(fields[11], 64)
		if err != nil {
			return nil, fmt.Errorf("failed to parse power draw: %w", err)
		}

		// Parse clock frequencies (in MHz)
		gpu.ClockGraphics, err = strconv.Atoi(fields[12])
		if err != nil {
			return nil, fmt.Errorf("failed to parse graphics clock: %w", err)
		}

		gpu.ClockMemory, err = strconv.Atoi(fields[13])
		if err != nil {
			return nil, fmt.Errorf("failed to parse memory clock: %w", err)
		}

		gpus = append(gpus, gpu)
	}

	return gpus, nil
}

// stripDockerLogHeaders removes Docker log headers from raw log output
// Docker logs include 8-byte headers: 1 byte stream type, 3 bytes padding, 4 bytes size
func stripDockerLogHeaders(logData []byte) string {
	var result strings.Builder

	for i := 0; i < len(logData); {
		// Check if we have enough bytes for a header
		if i+8 > len(logData) {
			// Not enough bytes for a complete header, treat remaining as data
			result.Write(logData[i:])
			break
		}

		// Read the 4-byte size from bytes 4-7 (big-endian)
		size := int(logData[i+4])<<24 | int(logData[i+5])<<16 | int(logData[i+6])<<8 | int(logData[i+7])

		// Skip the 8-byte header
		dataStart := i + 8
		dataEnd := dataStart + size

		// Make sure we don't read past the end of the buffer
		if dataEnd > len(logData) {
			dataEnd = len(logData)
		}

		// Append the actual data (skip the header)
		if dataStart < len(logData) {
			result.Write(logData[dataStart:dataEnd])
		}

		// Move to the next header
		i = dataEnd
	}

	return result.String()
}

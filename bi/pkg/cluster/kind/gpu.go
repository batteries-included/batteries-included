package kind

import (
	"bi/pkg/cluster/util"
	"context"
	_ "embed"
	"fmt"
	"io"
	"log/slog"
	"os/exec"
	"strings"

	"github.com/docker/docker/api/types/container"
	"github.com/vbauerster/mpb/v8"
	"sigs.k8s.io/kind/pkg/cluster"
	"sigs.k8s.io/kind/pkg/cluster/nodes"
)

//go:embed scripts/install-nvidia-toolkit.sh
var installNvidiaToolkitScript string

//go:embed scripts/configure-containerd.sh
var configureContainerdScript string

//go:embed scripts/patch-nvidia-params.sh
var patchNvidiaParamsScript string

var ubuntuImage = "ubuntu:24.04"

// detectGPUs checks if NVIDIA GPUs are available on the host
func (c *KindClusterProvider) detectGPUs(ctx context.Context) error {
	// Check if GPU auto-discovery is disabled via flag
	if !c.nvidiaAutoDiscovery {
		c.logger.Info("GPU auto-discovery disabled via --nvidia-auto-discovery=false flag")
		c.gpuAvailable = false
		c.gpuCount = 0
		return nil
	}

	// Try to get GPU information using nvidia-smi locally first
	output, err := c.tryNvidiaSmiLocal(ctx)
	if err != nil {
		c.logger.Debug("Local nvidia-smi failed, trying Docker fallback", slog.String("error", err.Error()))

		// Fallback to running nvidia-smi in Docker container
		output, err = c.tryNvidiaSmiDocker(ctx)
		if err != nil {
			c.logger.Debug("Docker nvidia-smi also failed, no GPUs available", slog.String("error", err.Error()))
			c.gpuAvailable = false
			c.gpuCount = 0
			return nil
		}
		c.logger.Debug("GPU detection successful using Docker fallback")
	} else {
		c.logger.Debug("GPU detection successful using local nvidia-smi")
	}

	// Count GPUs from nvidia-smi output
	gpuCount := c.countGPUsFromOutput(output)

	c.gpuAvailable = gpuCount > 0
	c.gpuCount = gpuCount

	if c.gpuAvailable {
		c.logger.Info("NVIDIA GPUs detected", slog.Int("count", c.gpuCount))
	} else {
		c.logger.Debug("No NVIDIA GPUs detected")
	}

	return nil
}

// tryNvidiaSmiLocal attempts to run nvidia-smi locally on the host
func (c *KindClusterProvider) tryNvidiaSmiLocal(ctx context.Context) (string, error) {
	cmd := exec.CommandContext(ctx, "nvidia-smi", "-L")
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("local nvidia-smi failed: %w", err)
	}
	return string(output), nil
}

// tryNvidiaSmiDocker attempts to run nvidia-smi inside a Docker container
func (c *KindClusterProvider) tryNvidiaSmiDocker(ctx context.Context) (string, error) {
	if c.dockerClient == nil {
		// Fallback to command execution if Docker client is not available
		return c.tryNvidiaSmiDockerCommand(ctx)
	}

	// Try with nvidia runtime first
	output, err := c.runNvidiaSmiContainer(ctx, true, false)
	if err != nil {
		c.logger.Debug("Docker with nvidia runtime failed, trying volume mount approach", slog.String("error", err.Error()))

		// Fallback to volume mount approach as mentioned in nvkind README
		output, err = c.runNvidiaSmiContainer(ctx, false, true)
		if err != nil {
			return "", fmt.Errorf("docker nvidia-smi failed: %w", err)
		}
	}
	return output, nil
}

// tryNvidiaSmiDockerCommand is a fallback function that uses command execution
func (c *KindClusterProvider) tryNvidiaSmiDockerCommand(ctx context.Context) (string, error) {
	// Try with nvidia runtime first
	cmd := exec.CommandContext(ctx, "docker", "run", "--rm", "--runtime=nvidia",
		"-e", "NVIDIA_VISIBLE_DEVICES=all", ubuntuImage, "nvidia-smi", "-L")
	output, err := cmd.Output()
	if err != nil {
		c.logger.Debug("Docker with nvidia runtime failed, trying volume mount approach", slog.String("error", err.Error()))

		// Fallback to volume mount approach as mentioned in nvkind README
		cmd = exec.CommandContext(ctx, "docker", "run", "--rm",
			"-v", "/dev/null:/var/run/nvidia-container-devices/all",
			ubuntuImage, "nvidia-smi", "-L")
		output, err = cmd.Output()
		if err != nil {
			return "", fmt.Errorf("docker nvidia-smi failed: %w", err)
		}
	}
	return string(output), nil
}

// runNvidiaSmiContainer runs nvidia-smi in a Docker container using the Docker client API
func (c *KindClusterProvider) runNvidiaSmiContainer(ctx context.Context, useNvidiaRuntime, useVolumeMount bool) (string, error) {
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
	containerConfig := &container.Config{
		Image: ubuntuImage,
		Cmd:   []string{"nvidia-smi", "-L"},
	}

	if useNvidiaRuntime {
		containerConfig.Env = []string{"NVIDIA_VISIBLE_DEVICES=all"}
	}

	// Create container
	resp, err := c.dockerClient.ContainerCreate(ctx, containerConfig, hostConfig, nil, nil, "")
	if err != nil {
		return "", fmt.Errorf("failed to create container: %w", err)
	}

	// Start container
	if err := c.dockerClient.ContainerStart(ctx, resp.ID, container.StartOptions{}); err != nil {
		return "", fmt.Errorf("failed to start container: %w", err)
	}

	// Wait for container to finish
	statusCh, errCh := c.dockerClient.ContainerWait(ctx, resp.ID, container.WaitConditionNotRunning)
	select {
	case err := <-errCh:
		if err != nil {
			return "", fmt.Errorf("error waiting for container: %w", err)
		}
	case status := <-statusCh:
		if status.StatusCode != 0 {
			// Get logs for error details
			logs, _ := c.dockerClient.ContainerLogs(ctx, resp.ID, container.LogsOptions{
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
	logs, err := c.dockerClient.ContainerLogs(ctx, resp.ID, container.LogsOptions{
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

	return string(logData), nil
}

// countGPUsFromOutput parses nvidia-smi output and counts the number of GPUs
func (c *KindClusterProvider) countGPUsFromOutput(output string) int {
	lines := strings.Split(strings.TrimSpace(output), "\n")
	gpuCount := 0
	for _, line := range lines {
		if strings.HasPrefix(line, "GPU ") && strings.Contains(line, ":") {
			gpuCount++
		}
	}
	return gpuCount
}

// setupGPUNodes configures GPU support on the cluster nodes after creation
func (c *KindClusterProvider) setupGPUNodes(ctx context.Context, kindProvider *cluster.Provider, clusterName string, progressReporter *util.ProgressReporter) error {
	if !c.gpuAvailable {
		return nil
	}

	var gpuBar *mpb.Bar
	if progressReporter != nil {
		gpuBar = progressReporter.ForGPUSetup()
	}

	util.IncrementWithMessage(gpuBar, "Setting up GPU support on cluster nodes")

	// Get all nodes in the cluster
	nodeList, err := kindProvider.ListInternalNodes(clusterName)
	if err != nil {
		return fmt.Errorf("failed to list nodes: %w", err)
	}

	util.IncrementWithMessage(gpuBar, "Found cluster nodes")

	// Update total count: start(1) + found nodes(1) + setup per node(len) + complete(1)
	if gpuBar != nil {
		totalSteps := 2 + len(nodeList) + 1
		gpuBar.SetTotal(int64(totalSteps), false)
	}

	// Setup GPU support on all nodes (both control plane and worker nodes may need GPU support)
	for _, node := range nodeList {
		if err := c.setupGPUNode(ctx, node, gpuBar); err != nil {
			return fmt.Errorf("failed to setup GPU support on node %s: %w", node.String(), err)
		}
	}

	util.IncrementWithMessage(gpuBar, "GPU setup completed")
	util.SetTotalAndComplete(gpuBar)
	return nil
}

// setupGPUNode configures GPU support on a single node
func (c *KindClusterProvider) setupGPUNode(ctx context.Context, node nodes.Node, gpuBar *mpb.Bar) error {
	c.logger.Info("Setting up GPU support on node", slog.String("node", node.String()))

	// Install nvidia-container-toolkit
	c.logger.Debug("Installing nvidia-container-toolkit", slog.String("node", node.String()))
	if err := c.installContainerToolkit(ctx, node); err != nil {
		return fmt.Errorf("failed to install container toolkit: %w", err)
	}
	util.IncrementWithMessage(gpuBar, fmt.Sprintf("Installed container toolkit on %s", node.String()))

	// Configure containerd runtime
	c.logger.Debug("Configuring containerd runtime", slog.String("node", node.String()))
	if err := c.configureContainerRuntime(ctx, node); err != nil {
		return fmt.Errorf("failed to configure container runtime: %w", err)
	}

	// Patch /proc/driver/nvidia
	c.logger.Debug("Patching /proc/driver/nvidia", slog.String("node", node.String()))
	if err := c.patchProcDriverNvidia(ctx, node); err != nil {
		return fmt.Errorf("failed to patch /proc/driver/nvidia: %w", err)
	}

	c.logger.Info("GPU support setup completed on node", slog.String("node", node.String()))
	return nil
}

// installContainerToolkit installs the NVIDIA container toolkit in the node
func (c *KindClusterProvider) installContainerToolkit(ctx context.Context, node nodes.Node) error {
	return c.runScriptOnNode(ctx, node, installNvidiaToolkitScript)
}

// configureContainerRuntime configures containerd to use the NVIDIA runtime
func (c *KindClusterProvider) configureContainerRuntime(ctx context.Context, node nodes.Node) error {
	return c.runScriptOnNode(ctx, node, configureContainerdScript)
}

// patchProcDriverNvidia patches /proc/driver/nvidia to allow GPU access
func (c *KindClusterProvider) patchProcDriverNvidia(ctx context.Context, node nodes.Node) error {
	// Unmount the masked /proc/driver/nvidia to allow dynamically generated
	// MIG devices to be discovered. The || true ensures the script continues even if unmount fails
	script1 := `umount -R /proc/driver/nvidia || true`
	if err := c.runScriptOnNode(ctx, node, script1); err != nil {
		return fmt.Errorf("failed to unmount /proc/driver/nvidia: %w", err)
	}

	// Make it so that calls into nvidia-smi / libnvidia-ml.so do not attempt
	// to recreate device nodes or reset their permissions if tampered with
	if err := c.runScriptOnNode(ctx, node, patchNvidiaParamsScript); err != nil {
		return fmt.Errorf("failed to patch nvidia params: %w", err)
	}
	c.logger.Debug("GPU device nodes configured for all GPU access")
	return nil
}

// runScriptOnNode executes a script on the given node using Docker client API
func (c *KindClusterProvider) runScriptOnNode(ctx context.Context, node nodes.Node, script string) error {
	if c.dockerClient == nil {
		// Fallback to command execution if Docker client is not available
		return c.runScriptOnNodeCommand(ctx, node, script)
	}

	return c.runScriptOnNodeWithDockerClient(ctx, node, script)
}

// runScriptOnNodeCommand is a fallback function that uses command execution
func (c *KindClusterProvider) runScriptOnNodeCommand(ctx context.Context, node nodes.Node, script string) error {
	if c.dockerClient != nil {
		// If we have a Docker client, use it directly instead of exec commands
		return c.runScriptOnNodeWithDockerClient(ctx, node, script)
	}

	// Ultimate fallback to command execution if no Docker client is available
	cmd := exec.CommandContext(ctx, "docker", "exec", node.String(), "bash", "-c", script)
	output, err := cmd.CombinedOutput()
	if err != nil {
		c.logger.Error("Failed to run script on node",
			slog.String("node", node.String()),
			slog.String("script", script),
			slog.String("output", string(output)),
			slog.String("error", err.Error()))
		return err
	}

	c.logger.Debug("Script executed successfully on node",
		slog.String("node", node.String()),
		slog.String("output", string(output)))

	return nil
}

// runScriptOnNodeWithDockerClient executes a script using the Docker client API
func (c *KindClusterProvider) runScriptOnNodeWithDockerClient(ctx context.Context, node nodes.Node, script string) error {
	// Create exec configuration
	execConfig := container.ExecOptions{
		Cmd:          []string{"bash", "-c", script},
		AttachStdout: true,
		AttachStderr: true,
	}

	// Create exec instance
	execIDResp, err := c.dockerClient.ContainerExecCreate(ctx, node.String(), execConfig)
	if err != nil {
		return fmt.Errorf("failed to create exec instance: %w", err)
	}

	// Start the exec instance
	execStartConfig := container.ExecStartOptions{
		Detach: false,
	}

	hijackedResp, err := c.dockerClient.ContainerExecAttach(ctx, execIDResp.ID, execStartConfig)
	if err != nil {
		return fmt.Errorf("failed to attach to exec instance: %w", err)
	}
	defer hijackedResp.Close()

	// Read the output
	var outputBuf strings.Builder
	_, err = io.Copy(&outputBuf, hijackedResp.Reader)
	if err != nil {
		return fmt.Errorf("failed to read exec output: %w", err)
	}

	// Check exec exit code
	execInspect, err := c.dockerClient.ContainerExecInspect(ctx, execIDResp.ID)
	if err != nil {
		return fmt.Errorf("failed to inspect exec instance: %w", err)
	}

	output := outputBuf.String()
	if execInspect.ExitCode != 0 {
		c.logger.Error("Failed to run script on node",
			slog.String("node", node.String()),
			slog.String("script", script),
			slog.String("output", output),
			slog.Int("exit_code", execInspect.ExitCode))
		return fmt.Errorf("script execution failed with exit code %d", execInspect.ExitCode)
	}

	c.logger.Debug("Script executed successfully on node",
		slog.String("node", node.String()),
		slog.String("output", output))

	return nil
}

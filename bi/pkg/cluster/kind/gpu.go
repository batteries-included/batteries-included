package kind

import (
	"bi/pkg/cluster/util"
	"bi/pkg/ctkutil"
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

// detectGPUs checks if NVIDIA GPUs are available on the host
func (c *KindClusterProvider) detectGPUs(ctx context.Context) error {
	// Check if GPU auto-discovery is disabled via flag
	if !c.nvidiaAutoDiscovery {
		c.logger.Info("GPU auto-discovery disabled via --nvidia-auto-discovery=false flag")
		c.gpuAvailable = false
		c.gpuCount = 0
		return nil
	}

	// Use the centralized GPU detector
	detector := ctkutil.NewGPUDetector(c.dockerClient)
	gpuCount, err := detector.DetectGPUs(ctx)
	if err != nil {
		c.logger.Debug("GPU detection failed", slog.String("error", err.Error()))
		c.gpuAvailable = false
		c.gpuCount = 0
		return nil
	}

	c.gpuAvailable = gpuCount > 0
	c.gpuCount = gpuCount

	if c.gpuAvailable {
		c.logger.Info("NVIDIA GPUs detected", slog.Int("count", c.gpuCount))

		// Validate NVIDIA container toolkit setup
		if err := c.validateNvidiaContainerToolkit(ctx); err != nil {
			c.logger.Warn("NVIDIA container toolkit validation failed, disabling GPU support",
				slog.String("error", err.Error()))
			c.gpuAvailable = false
			c.gpuCount = 0
		}
	} else {
		c.logger.Debug("No NVIDIA GPUs detected")
	}

	return nil
}

// validateNvidiaContainerToolkit validates the NVIDIA container toolkit setup
func (c *KindClusterProvider) validateNvidiaContainerToolkit(ctx context.Context) error {
	return ctkutil.ValidateNvidiaContainerToolkit(ctx, c.dockerClient != nil)
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

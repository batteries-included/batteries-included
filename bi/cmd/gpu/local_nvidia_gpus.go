/*
Copyright © 2025 Batteries Included
*/
package gpu

import (
	"bi/pkg/ctkutil"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"text/tabwriter"

	"github.com/spf13/cobra"
)

var (
	outputFormat string
)

var localNvidiaGPUsCommand = &cobra.Command{
	Use:   "local-nvidia-gpus",
	Short: "Display information about local NVIDIA GPUs",
	Long: `Query and display detailed information about NVIDIA GPUs available on the local system.
This command uses nvidia-smi to gather comprehensive GPU information that can be useful
for understanding GPU capabilities and current usage in Kubernetes environments.

The command supports both text and JSON output formats for integration with other tools.`,
	RunE: runLocalNvidiaGPUs,
}

func init() {
	localNvidiaGPUsCommand.Flags().StringVarP(&outputFormat, "format", "f", "text",
		"Output format: 'text' for human-readable table or 'json' for machine-readable JSON")
	gpuCommand.AddCommand(localNvidiaGPUsCommand)
}

func runLocalNvidiaGPUs(cmd *cobra.Command, args []string) error {
	ctx := context.Background()

	// Create GPU detector
	detector := ctkutil.NewGPUDetector(nil)

	// Get GPU information
	gpus, err := detector.DetectGPUInfo(ctx)
	if err != nil {
		return fmt.Errorf("failed to get GPU information: %w", err)
	}

	if len(gpus) == 0 {
		fmt.Println("No NVIDIA GPUs found on this system")
		return nil
	}

	// Output in requested format
	switch strings.ToLower(outputFormat) {
	case "json":
		return outputGPUsAsJSON(gpus)
	case "text":
		return outputGPUsAsText(gpus)
	default:
		return fmt.Errorf("unsupported output format: %s (supported: text, json)", outputFormat)
	}
}

func outputGPUsAsJSON(gpus []ctkutil.GPUInfo) error {
	encoder := json.NewEncoder(os.Stdout)
	encoder.SetIndent("", "  ")
	return encoder.Encode(gpus)
}

func outputGPUsAsText(gpus []ctkutil.GPUInfo) error {
	// Create a tabwriter for aligned output
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)

	// Print header
	fmt.Fprintln(w, "INDEX\tNAME\tPCI_BUS_ID\tDRIVER\tMEMORY(MB)\tGPU_UTIL(%)\tMEM_UTIL(%)\tTEMP(°C)\tPOWER(W)\tGFX_CLK(MHz)\tMEM_CLK(MHz)")
	fmt.Fprintln(w, "-----\t----\t----------\t------\t----------\t---------\t---------\t--------\t--------\t-----------\t-----------")

	// Print GPU information
	for _, gpu := range gpus {
		memoryInfo := fmt.Sprintf("%d/%d", gpu.MemoryUsed, gpu.MemoryTotal)
		fmt.Fprintf(w, "%d\t%s\t%s\t%s\t%s\t%d\t%d\t%d\t%.1f\t%d\t%d\n",
			gpu.Index,
			gpu.Name,
			gpu.PCIBusID,
			gpu.DriverVersion,
			memoryInfo,
			gpu.UtilizationGPU,
			gpu.UtilizationMem,
			gpu.Temperature,
			gpu.PowerDraw,
			gpu.ClockGraphics,
			gpu.ClockMemory,
		)
	}

	// Flush the tabwriter
	return w.Flush()
}

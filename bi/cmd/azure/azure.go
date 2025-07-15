package azure

import (
	"github.com/spf13/cobra"
)

// NewAzureCmd creates a new azure command
func NewAzureCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "azure",
		Short: "Azure commands for Kubernetes clusters",
		Long:  `Commands for interacting with Azure Kubernetes Service (AKS) clusters.`,
	}

	cmd.AddCommand(NewGetTokenCmd())
	cmd.AddCommand(NewOutputsCmd())

	return cmd
}

func init() {
	// Register the azure command with the root command
	// This will be called when the package is imported
}

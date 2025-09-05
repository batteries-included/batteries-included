package azure

import (
	"bi/cmd"

	"github.com/spf13/cobra"
)

var azureCmd = &cobra.Command{
	Use:   "azure",
	Short: "Azure commands for Kubernetes clusters",
	Long:  `Commands for interacting with Azure Kubernetes Service (AKS) clusters.`,
}

func init() {
	cmd.RootCmd.AddCommand(azureCmd)
}

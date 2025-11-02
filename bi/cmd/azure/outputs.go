package azure

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

// AzureOutputs represents the Azure cluster configuration outputs
type AzureOutputs struct {
	ResourceGroupName    string `json:"resource_group_name"`
	ClusterName          string `json:"cluster_name"`
	Location             string `json:"location"`
	NodeResourceGroup    string `json:"node_resource_group"`
	KubeletIdentityID    string `json:"kubelet_identity_id"`
	TenantID             string `json:"tenant_id"`
	SubscriptionID       string `json:"subscription_id"`
	VnetName             string `json:"vnet_name"`
	SubnetName           string `json:"subnet_name"`
}

// NewOutputsCmd creates a new outputs command for Azure
func NewOutputsCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "outputs",
		Short: "Output Azure AKS cluster configuration details",
		Long:  `Output Azure AKS cluster configuration details from environment variables or Azure CLI.`,
		RunE:  runOutputs,
	}

	return cmd
}

func runOutputs(cmd *cobra.Command, args []string) error {
	outputs := AzureOutputs{
		ResourceGroupName: getEnvOrDefault("AZURE_RESOURCE_GROUP", ""),
		ClusterName:       getEnvOrDefault("AZURE_CLUSTER_NAME", ""),
		Location:          getEnvOrDefault("AZURE_LOCATION", ""),
		NodeResourceGroup: getEnvOrDefault("AZURE_NODE_RESOURCE_GROUP", ""),
		KubeletIdentityID: getEnvOrDefault("AZURE_KUBELET_IDENTITY_ID", ""),
		TenantID:          getEnvOrDefault("AZURE_TENANT_ID", ""),
		SubscriptionID:    getEnvOrDefault("AZURE_SUBSCRIPTION_ID", ""),
		VnetName:          getEnvOrDefault("AZURE_VNET_NAME", ""),
		SubnetName:        getEnvOrDefault("AZURE_SUBNET_NAME", ""),
	}

	jsonOutput, err := json.MarshalIndent(outputs, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal Azure outputs: %w", err)
	}

	fmt.Println(string(jsonOutput))
	return nil
}

func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func init() {
	azureCmd.AddCommand(NewOutputsCmd())
}

package azure

import (
	"context"
	"fmt"
	"os"

	"github.com/Azure/azure-sdk-for-go/sdk/azcore/policy"
	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/spf13/cobra"
)

// NewGetTokenCmd creates a new get-token command for Azure
func NewGetTokenCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "get-token",
		Short: "Get Azure authentication token for AKS cluster access",
		Long:  `Retrieve an Azure authentication token for accessing AKS cluster resources.`,
		RunE:  runGetToken,
	}

	return cmd
}

func runGetToken(cmd *cobra.Command, args []string) error {
	ctx := context.Background()

	// Create a default Azure credential chain
	cred, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		return fmt.Errorf("failed to create Azure credential: %w", err)
	}

	// Get token for Azure Resource Manager
	token, err := cred.GetToken(ctx, policy.TokenRequestOptions{
		Scopes: []string{"https://management.azure.com/.default"},
	})
	if err != nil {
		return fmt.Errorf("failed to get Azure token: %w", err)
	}

	// Output the token
	fmt.Println(token.Token)
	return nil
}

func init() {
	// Set environment variables for Azure authentication if not already set
	if os.Getenv("AZURE_CLIENT_ID") == "" {
		// Try to use managed identity or Azure CLI credentials
		os.Setenv("AZURE_AUTH_LOCATION", "")
	}
}

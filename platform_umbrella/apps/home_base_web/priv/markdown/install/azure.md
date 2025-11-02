### For Azure

On Microsoft Azure, Batteries Included will create a new AKS cluster
and deploy batteries needed to automatically run your cluster. We will:

- Create a new AKS cluster with managed identity
- Set up Azure Virtual Network with proper subnets
- Start the Batteries Included control server
- Deploy the Azure Karpenter battery for node autoscaling
- Deploy the Azure Load Balancer Controller battery
- Deploy the Istio battery for mTLS and service mesh
- Deploy the Istio Ingress Gateway battery for web traffic routing
- Deploy the Cert Manager battery for SSL certificates

#### Needed

For Azure installs, the `bi` binary will need:

- An Azure account with Contributor permissions
- Authenticated via `az login` or service principal
- Azure CLI installed and configured
- Required Azure resource providers registered:
  - Microsoft.ContainerService
  - Microsoft.Storage
  - Microsoft.Network
  - Microsoft.ManagedIdentity
  - Microsoft.Authorization

#### Azure Configuration

The following Azure-specific settings can be configured:

- **Location**: Azure region (default: "East US")
- **Subscription ID**: Your Azure subscription ID
- **Resource Group**: Will be created automatically
- **VM Size**: Node pool VM size (default: "Standard_D2s_v3")
- **Node Count**: Initial number of nodes (default: 3)
- **Kubernetes Version**: AKS version (default: "1.28.0")

#### Authentication

Azure authentication can be configured in several ways:

1. **Azure CLI**: Run `az login` to authenticate interactively
2. **Service Principal**: Set environment variables:
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`
3. **Managed Identity**: When running on Azure resources

#### Prerequisites

Before installing, ensure you have:

1. Azure CLI installed: `curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash`
2. Logged in to Azure: `az login`
3. Set your subscription: `az account set --subscription <subscription-id>`
4. Registered required providers: `az provider register --namespace Microsoft.ContainerService`

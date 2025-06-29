defmodule CommonCore.Resources.AzureTest do
  use ExUnit.Case, async: true

  alias CommonCore.Batteries.AzureLoadBalancerControllerConfig
  alias CommonCore.Batteries.AzureClusterAutoscalerConfig
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Resources.AzureLoadBalancerController
  alias CommonCore.Resources.AzureClusterAutoscaler
  alias CommonCore.Resources.StorageClass
  alias CommonCore.StateSummary

  describe "Azure Load Balancer Controller" do
    test "generates correct resources" do
      config = %AzureLoadBalancerControllerConfig{
        subscription_id: "test-subscription",
        resource_group_name: "test-rg",
        tenant_id: "test-tenant",
        location: "eastus",
        subnet_name: "test-subnet"
      }

      battery = %SystemBattery{
        type: :azure_load_balancer_controller,
        config: config
      }

      state = %StateSummary{
        cluster_name: "test-cluster",
        batteries: [battery]
      }

      resources = AzureLoadBalancerController.build(battery, state)

      # Should generate service account, deployment, and ingress class
      assert length(resources) >= 3

      # Check service account has correct annotations
      service_account = Enum.find(resources, &(&1.kind == "ServiceAccount"))
      assert service_account != nil
      assert service_account.metadata.annotations["azure.workload.identity/client-id"] == "test-subscription"
      assert service_account.metadata.labels["azure.workload.identity/use"] == "true"

      # Check deployment exists
      deployment = Enum.find(resources, &(&1.kind == "Deployment"))
      assert deployment != nil
      assert deployment.metadata.name == "azure-load-balancer-controller"

      # Check ingress class exists
      ingress_class = Enum.find(resources, &(&1.kind == "IngressClass"))
      assert ingress_class != nil
      assert ingress_class.spec.controller == "ingress.azure.io/alb"
    end
  end

  describe "Azure Cluster Autoscaler" do
    test "generates correct resources" do
      config = %AzureClusterAutoscalerConfig{
        subscription_id: "test-subscription",
        resource_group_name: "test-rg",
        tenant_id: "test-tenant",
        node_resource_group: "test-node-rg",
        image: "mcr.microsoft.com/oss/kubernetes/autoscaler/cluster-autoscaler:v1.28.0"
      }

      battery = %SystemBattery{
        type: :azure_cluster_autoscaler,
        config: config
      }

      state = %StateSummary{
        cluster_name: "test-cluster",
        batteries: [battery]
      }

      resources = AzureClusterAutoscaler.build(battery, state)

      # Should generate service account, cluster role, cluster role binding, and deployment
      assert length(resources) >= 4

      # Check service account
      service_account = Enum.find(resources, &(&1.kind == "ServiceAccount"))
      assert service_account != nil
      assert service_account.metadata.name == "azure-cluster-autoscaler"

      # Check cluster role
      cluster_role = Enum.find(resources, &(&1.kind == "ClusterRole"))
      assert cluster_role != nil
      assert cluster_role.metadata.name == "azure-cluster-autoscaler-role"

      # Check deployment
      deployment = Enum.find(resources, &(&1.kind == "Deployment"))
      assert deployment != nil
      assert deployment.metadata.name == "azure-cluster-autoscaler"

      # Check environment variables
      container = deployment.spec.template.spec.containers |> List.first()
      env_vars = container.env

      assert Enum.any?(env_vars, &(&1.name == "ARM_SUBSCRIPTION_ID" && &1.value == "test-subscription"))
      assert Enum.any?(env_vars, &(&1.name == "ARM_RESOURCE_GROUP" && &1.value == "test-rg"))
      assert Enum.any?(env_vars, &(&1.name == "ARM_TENANT_ID" && &1.value == "test-tenant"))
      assert Enum.any?(env_vars, &(&1.name == "AZURE_NODE_RESOURCE_GROUP" && &1.value == "test-node-rg"))
    end
  end

  describe "Azure Storage Classes" do
    test "generates AKS storage classes" do
      storage_classes = StorageClass.generate_aks_storage_classes()

      assert length(storage_classes) == 4

      # Check default storage class
      default_sc = Enum.find(storage_classes, &(&1.metadata.name == "default"))
      assert default_sc != nil
      assert default_sc.provisioner == "kubernetes.io/azure-disk"

      # Check managed premium (should be default)
      premium_sc = Enum.find(storage_classes, &(&1.metadata.name == "managed-premium"))
      assert premium_sc != nil
      assert premium_sc.provisioner == "disk.csi.azure.com"
      assert premium_sc.metadata.annotations["storageclass.kubernetes.io/is-default-class"] == "true"
      assert premium_sc.parameters["storageaccounttype"] == "Premium_LRS"

      # Check managed standard
      standard_sc = Enum.find(storage_classes, &(&1.metadata.name == "managed-standard"))
      assert standard_sc != nil
      assert standard_sc.parameters["storageaccounttype"] == "Standard_LRS"

      # Check managed standard SSD
      ssd_sc = Enum.find(storage_classes, &(&1.metadata.name == "managed-standard-ssd"))
      assert ssd_sc != nil
      assert ssd_sc.parameters["storageaccounttype"] == "StandardSSD_LRS"
    end

    test "does not generate AWS storage classes for Azure" do
      # This test ensures Azure clusters don't get AWS storage classes
      aws_storage_classes = StorageClass.generate_eks_storage_classes()
      azure_storage_classes = StorageClass.generate_aks_storage_classes()

      # Ensure they are different
      aws_names = Enum.map(aws_storage_classes, & &1.metadata.name)
      azure_names = Enum.map(azure_storage_classes, & &1.metadata.name)

      assert aws_names != azure_names
      assert "gp3" in aws_names
      assert "gp3" not in azure_names
      assert "managed-premium" in azure_names
      assert "managed-premium" not in aws_names
    end
  end

  describe "Azure Battery Configurations" do
    test "AzureLoadBalancerControllerConfig has correct defaults" do
      config = %AzureLoadBalancerControllerConfig{}

      assert config.image == "mcr.microsoft.com/oss/kubernetes/azure-load-balancer-controller:v1.7.0"
      assert config.replica_count == 2
      assert config.subscription_id == nil
      assert config.resource_group_name == nil
      assert config.tenant_id == nil
      assert config.location == nil
      assert config.subnet_name == nil
    end

    test "AzureClusterAutoscalerConfig has correct defaults" do
      config = %AzureClusterAutoscalerConfig{}

      assert config.image == "mcr.microsoft.com/oss/kubernetes/autoscaler/cluster-autoscaler:v1.28.0"
      assert config.scale_down_delay_after_add == "10m"
      assert config.scale_down_unneeded_time == "10m"
      assert config.max_node_provision_time == "15m"
      assert config.subscription_id == nil
      assert config.resource_group_name == nil
      assert config.tenant_id == nil
      assert config.node_resource_group == nil
    end
  end
end

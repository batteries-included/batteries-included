defmodule CommonCore.Resources.AzureClusterAutoscaler do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "azure-cluster-autoscaler"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.StateSummary.Core

  resource(:service_account_azure_cluster_autoscaler, battery, state) do
    namespace = base_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.annotation("azure.workload.identity/client-id", battery.config.subscription_id)
    |> B.label("azure.workload.identity/use", "true")
  end

  resource(:cluster_role_azure_cluster_autoscaler) do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["events", "endpoints"],
        "verbs" => ["create", "patch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["pods/eviction"],
        "verbs" => ["create"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["pods/status"],
        "verbs" => ["update"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["endpoints"],
        "resourceNames" => ["cluster-autoscaler"],
        "verbs" => ["get", "update"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["nodes"],
        "verbs" => ["watch", "list", "get", "update"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["pods", "services", "replicationcontrollers", "persistentvolumeclaims", "persistentvolumes"],
        "verbs" => ["watch", "list", "get"]
      },
      %{
        "apiGroups" => ["extensions"],
        "resources" => ["replicasets", "daemonsets"],
        "verbs" => ["watch", "list", "get"]
      },
      %{
        "apiGroups" => ["policy"],
        "resources" => ["poddisruptionbudgets"],
        "verbs" => ["watch", "list"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["statefulsets", "replicasets", "daemonsets"],
        "verbs" => ["watch", "list", "get"]
      },
      %{
        "apiGroups" => ["storage.k8s.io"],
        "resources" => ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities"],
        "verbs" => ["watch", "list", "get"]
      },
      %{
        "apiGroups" => ["batch", "extensions"],
        "resources" => ["jobs"],
        "verbs" => ["get", "list", "watch", "patch"]
      },
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resources" => ["leases"],
        "verbs" => ["create"]
      },
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resourceNames" => ["cluster-autoscaler"],
        "resources" => ["leases"],
        "verbs" => ["get", "update"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("#{@app_name}-role")
    |> B.rules(rules)
  end

  resource(:cluster_role_binding_azure_cluster_autoscaler, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("#{@app_name}-rolebinding")
    |> B.role_ref(B.build_cluster_role_ref("#{@app_name}-role"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:deployment_azure_cluster_autoscaler, battery, state) do
    namespace = base_namespace(state)
    cluster_name = Core.cluster_name(state)

    template =
      %{}
      |> B.spec(%{
        "serviceAccountName" => @app_name,
        "nodeSelector" => %{"kubernetes.io/os" => "linux"},
        "containers" => [
          %{
            "name" => @app_name,
            "image" => battery.config.image,
            "command" => ["./cluster-autoscaler"],
            "args" => [
              "--v=4",
              "--stderrthreshold=info",
              "--cloud-provider=azure",
              "--skip-nodes-with-local-storage=false",
              "--expander=random",
              "--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/#{cluster_name}",
              "--balance-similar-node-groups",
              "--scale-down-delay-after-add=#{battery.config.scale_down_delay_after_add}",
              "--scale-down-unneeded-time=#{battery.config.scale_down_unneeded_time}",
              "--max-node-provision-time=#{battery.config.max_node_provision_time}"
            ],
            "env" => [
              %{
                "name" => "ARM_SUBSCRIPTION_ID",
                "value" => battery.config.subscription_id
              },
              %{
                "name" => "ARM_RESOURCE_GROUP",
                "value" => battery.config.resource_group_name
              },
              %{
                "name" => "ARM_TENANT_ID",
                "value" => battery.config.tenant_id
              },
              %{
                "name" => "ARM_VM_TYPE",
                "value" => "vmss"
              },
              %{
                "name" => "AZURE_CLUSTER_NAME",
                "value" => cluster_name
              },
              %{
                "name" => "AZURE_NODE_RESOURCE_GROUP",
                "value" => battery.config.node_resource_group
              }
            ],
            "resources" => %{
              "limits" => %{"cpu" => "100m", "memory" => "300Mi"},
              "requests" => %{"cpu" => "100m", "memory" => "300Mi"}
            },
            "securityContext" => %{
              "allowPrivilegeEscalation" => false,
              "readOnlyRootFilesystem" => true,
              "runAsNonRoot" => true,
              "runAsUser" => 65534
            }
          }
        ]
      })

    :deployment
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.label("battery/app", @app_name)
    |> B.spec(%{
      "replicas" => 1,
      "selector" => %{"matchLabels" => %{"app" => @app_name}},
      "template" => template |> B.label("app", @app_name)
    })
  end
end

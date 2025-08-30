defmodule CommonCore.Resources.AzureLoadBalancerController do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "azure-load-balancer-controller"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.StateSummary.Core

  resource(:service_account_azure_load_balancer_controller, battery, state) do
    namespace = base_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.annotation("azure.workload.identity/client-id", battery.config.kubelet_identity_id)
    |> B.label("azure.workload.identity/use", "true")
  end

  resource(:cluster_role_azure_load_balancer_controller) do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["events"],
        "verbs" => ["create", "patch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["services"],
        "verbs" => ["get", "list", "watch", "update", "patch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["services/status"],
        "verbs" => ["update", "patch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["nodes"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingresses"],
        "verbs" => ["get", "list", "watch", "update", "patch"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingresses/status"],
        "verbs" => ["update", "patch"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingressclasses"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resources" => ["leases"],
        "verbs" => ["get", "create", "update", "patch"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("#{@app_name}-role")
    |> B.rules(rules)
  end

  resource(:cluster_role_binding_azure_load_balancer_controller, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("#{@app_name}-rolebinding")
    |> B.role_ref(B.build_cluster_role_ref("#{@app_name}-role"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:deployment_azure_load_balancer_controller, battery, state) do
    namespace = base_namespace(state)
    cluster_name = battery.config.cluster_name || Core.cluster_name(state)

    template =
      %{}
      |> B.spec(%{
        "serviceAccountName" => @app_name,
        "nodeSelector" => %{"kubernetes.io/os" => "linux"},
        "containers" => [
          %{
            "name" => @app_name,
            "image" => battery.config.image,
            "args" => [
              "--v=2",
              "--cloud-provider-config=/etc/kubernetes/azure.json",
              "--cluster-name=#{cluster_name}",
              "--cloud-config-secret-name=azure-cloud-provider",
              "--cloud-config-secret-namespace=kube-system"
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
                "name" => "AZURE_CLUSTER_NAME",
                "value" => cluster_name
              },
              %{
                "name" => "AZURE_NODE_RESOURCE_GROUP",
                "value" => battery.config.node_resource_group
              }
            ],
            "resources" => %{
              "limits" => %{"cpu" => "200m", "memory" => "500Mi"},
              "requests" => %{"cpu" => "100m", "memory" => "200Mi"}
            },
            "securityContext" => %{
              "allowPrivilegeEscalation" => false,
              "readOnlyRootFilesystem" => true,
              "runAsNonRoot" => true,
              "runAsUser" => 65534
            },
            "volumeMounts" => [
              %{
                "name" => "azure-cloud-config",
                "mountPath" => "/etc/kubernetes",
                "readOnly" => true
              }
            ]
          }
        ],
        "volumes" => [
          %{
            "name" => "azure-cloud-config",
            "secret" => %{
              "secretName" => "azure-cloud-provider"
            }
          }
        ]
      })

    spec = %{
      "replicas" => 1,
      "selector" => %{"matchLabels" => %{"app" => @app_name}},
      "template" => template |> B.app_labels(@app_name)
    }

    :deployment
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.add_owner(battery)
    |> B.spec(spec)
  end



  resource(:ingress_class_azure_load_balancer_controller) do
    :ingress_class
    |> B.build_resource()
    |> B.name("azure")
    |> B.spec(%{
      "controller" => "ingress.k8s.azure/alb"
    })
    |> B.annotation("ingressclass.kubernetes.io/is-default-class", "false")
  end
end

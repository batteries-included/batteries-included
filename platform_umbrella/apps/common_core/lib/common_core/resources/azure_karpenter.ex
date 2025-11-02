defmodule CommonCore.Resources.AzureKarpenter do
  @moduledoc false

  use CommonCore.Resources.ResourceGenerator, app_name: "azure-karpenter"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.ApiVersionKind
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.StateSummary.Core

  @metrics_port 8000
  @health_probe_port 8081

  resource(:pod_disruption_budget_main, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("maxUnavailable", 1)
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})

    :pod_disruption_budget
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_account_main, battery, state) do
    namespace = base_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.annotation("azure.workload.identity/client-id", battery.config.client_id)
    |> B.annotation("azure.workload.identity/use", "true")
  end

  resource(:cluster_role_admin) do
    rules = [
      %{
        "apiGroups" => ["karpenter.sh"],
        "resources" => ["nodepools", "nodepools/status", "nodeclaims", "nodeclaims/status"],
        "verbs" => ["get", "list", "watch", "create", "delete", "patch"]
      },
      %{
        "apiGroups" => ["karpenter.azure.com"],
        "resources" => ["aksnodeclasses"],
        "verbs" => ["get", "list", "watch", "create", "delete", "patch"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("azure-karpenter-admin")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-admin", "true")
    |> B.rules(rules)
  end

  resource(:cluster_role_core) do
    rules = [
      %{
        "apiGroups" => ["karpenter.sh"],
        "resources" => ["nodepools", "nodepools/status", "nodeclaims", "nodeclaims/status"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => [
          "pods",
          "nodes",
          "persistentvolumes",
          "persistentvolumeclaims",
          "replicationcontrollers",
          "namespaces"
        ],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["storage.k8s.io"],
        "resources" => ["storageclasses", "csinodes", "volumeattachments"],
        "verbs" => ["get", "watch", "list"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["daemonsets", "deployments", "replicasets", "statefulsets"],
        "verbs" => ["list", "watch"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"apiGroups" => ["policy"], "resources" => ["poddisruptionbudgets"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => ["karpenter.sh"],
        "resources" => ["nodeclaims", "nodeclaims/status"],
        "verbs" => ["create", "delete", "update", "patch"]
      },
      %{
        "apiGroups" => ["karpenter.sh"],
        "resources" => ["nodepools", "nodepools/status"],
        "verbs" => ["update", "patch"]
      },
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]},
      %{"apiGroups" => [""], "resources" => ["nodes"], "verbs" => ["patch", "delete", "update"]},
      %{"apiGroups" => [""], "resources" => ["pods/eviction"], "verbs" => ["create"]},
      %{"apiGroups" => [""], "resources" => ["pods"], "verbs" => ["delete"]},
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions/status"],
        "resourceNames" => ["aksnodeclasses.karpenter.azure.com", "nodepools.karpenter.sh", "nodeclaims.karpenter.sh"],
        "verbs" => ["patch"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "resourceNames" => ["aksnodeclasses.karpenter.azure.com", "nodepools.karpenter.sh", "nodeclaims.karpenter.sh"],
        "verbs" => ["update"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("azure-karpenter-core")
    |> B.rules(rules)
  end

  resource(:cluster_role_main) do
    rules = [
      %{"apiGroups" => ["karpenter.azure.com"], "resources" => ["aksnodeclasses"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => ["karpenter.azure.com"],
        "resources" => ["aksnodeclasses", "aksnodeclasses/status"],
        "verbs" => ["patch", "update"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.rules(rules)
  end

  resource(:cluster_role_binding_core, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("azure-karpenter-core")
    |> B.role_ref(B.build_cluster_role_ref("azure-karpenter-core"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:cluster_role_binding_main, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.role_ref(B.build_cluster_role_ref(@app_name))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:role_main, _battery, state) do
    namespace = base_namespace(state)

    rules = [
      %{"apiGroups" => ["coordination.k8s.io"], "resources" => ["leases"], "verbs" => ["get", "watch"]},
      %{"apiGroups" => [""], "resources" => ["configmaps", "secrets"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["update"], "resourceNames" => ["#{@app_name}-cert"]},
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resourceNames" => ["azure-karpenter-leader-election"],
        "resources" => ["leases"],
        "verbs" => ["patch", "update"]
      },
      %{"apiGroups" => ["coordination.k8s.io"], "resources" => ["leases"], "verbs" => ["create"]}
    ]

    :role
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:role_binding_main, _battery, state) do
    namespace = base_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref(@app_name))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:service_main, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http-metrics", "port" => @metrics_port, "protocol" => "TCP", "targetPort" => "http-metrics"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})
      |> Map.put("type", "ClusterIP")

    :service
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:deployment_main, battery, state) do
    namespace = base_namespace(state)

    template =
      %{}
      |> Map.put(
        "metadata",
        %{
          "annotations" => nil,
          "labels" => %{"battery/app" => @app_name, "battery/managed" => "true", "azure.workload.identity/use" => "true"}
        }
      )
      |> Map.put(
        "spec",
        %{
          "affinity" => %{
            "nodeAffinity" => %{
              "requiredDuringSchedulingIgnoredDuringExecution" => %{
                "nodeSelectorTerms" => [
                  %{"matchExpressions" => [%{"key" => "karpenter.sh/nodepool", "operator" => "DoesNotExist"}]}
                ]
              }
            }
          },
          "containers" => [
            %{
              "env" => [
                %{"name" => "KUBERNETES_MIN_VERSION", "value" => "1.23.0"},
                %{"name" => "KARPENTER_SERVICE", "value" => @app_name},
                %{"name" => "LOG_LEVEL", "value" => "info"},
                %{"name" => "METRICS_PORT", "value" => "#{@metrics_port}"},
                %{"name" => "HEALTH_PROBE_PORT", "value" => "#{@health_probe_port}"},
                %{"name" => "SYSTEM_NAMESPACE", "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}},
                %{"name" => "CLUSTER_NAME", "value" => battery.config.cluster_name || Core.config_field(state, :cluster_name)},
                %{"name" => "RG", "value" => battery.config.resource_group_name},
                %{"name" => "LOCATION", "value" => battery.config.location},
                %{"name" => "KARPENTER_NAMESPACE", "value" => namespace},
                %{"name" => "AZURE_SUBSCRIPTION_ID", "value" => battery.config.subscription_id},
                %{"name" => "AZURE_TENANT_ID", "value" => battery.config.tenant_id},
                %{"name" => "AZURE_CLIENT_ID", "value" => battery.config.client_id}
              ],
              "image" => battery.config.image,
              "imagePullPolicy" => "IfNotPresent",
              "livenessProbe" => %{
                "httpGet" => %{"path" => "/healthz", "port" => "http"},
                "initialDelaySeconds" => 30,
                "timeoutSeconds" => 30
              },
              "name" => "controller",
              "ports" => [
                %{"containerPort" => @metrics_port, "name" => "http-metrics", "protocol" => "TCP"},
                %{"containerPort" => @health_probe_port, "name" => "http", "protocol" => "TCP"}
              ],
              "readinessProbe" => %{
                "httpGet" => %{"path" => "/readyz", "port" => "http"},
                "initialDelaySeconds" => 5,
                "timeoutSeconds" => 30
              },
              "resources" => %{
                "limits" => %{"cpu" => 1, "memory" => "1Gi"},
                "requests" => %{"cpu" => 1, "memory" => "1Gi"}
              },
              "securityContext" => %{
                "allowPrivilegeEscalation" => false,
                "capabilities" => %{"drop" => ["ALL"]},
                "readOnlyRootFilesystem" => true,
                "runAsGroup" => 65_536,
                "runAsNonRoot" => true,
                "runAsUser" => 65_536,
                "seccompProfile" => %{"type" => "RuntimeDefault"}
              }
            }
          ],
          "dnsPolicy" => "ClusterFirst",
          "nodeSelector" => %{"kubernetes.io/os" => "linux"},
          "priorityClassName" => "system-cluster-critical",
          "securityContext" => %{"fsGroup" => 65_536},
          "serviceAccountName" => @app_name,
          "tolerations" => [%{"key" => "CriticalAddonsOnly", "operator" => "Exists"}]
        }
      )
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("revisionHistoryLimit", 10)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name}}
      )
      |> Map.put("strategy", %{"type" => "Recreate"})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  # Default AKS NodeClass for Azure Karpenter
  resource(:aks_node_class_default, battery, state) do
    namespace = base_namespace(state)

    spec = %{
      "imageFamily" => battery.config.image_family,
      "imageVersion" => battery.config.image_version
    }

    :karpenter_aksnode_class
    |> B.build_resource()
    |> B.name("default")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  # Default NodePool for Azure Karpenter
  resource(:node_pool_default, battery, state) do
    namespace = base_namespace(state)

    spec = %{
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "karpenter.sh/provisioner-name" => "default"
          }
        },
        "spec" => %{
          "requirements" => [
            %{"key" => "kubernetes.io/arch", "operator" => "In", "values" => ["amd64"]},
            %{"key" => "kubernetes.io/os", "operator" => "In", "values" => ["linux"]},
            %{"key" => "karpenter.sh/capacity-type", "operator" => "In", "values" => ["on-demand"]},
            %{"key" => "node.kubernetes.io/instance-type", "operator" => "In", "values" => battery.config.instance_types}
          ],
          "nodeClassRef" => %{
            "apiVersion" => elem(ApiVersionKind.from_resource_type!(:karpenter_aksnode_class), 0),
            "kind" => elem(ApiVersionKind.from_resource_type!(:karpenter_aksnode_class), 1),
            "name" => "default"
          },
          "taints" => []
        }
      },
      "limits" => %{
        "cpu" => 1000
      },
      "disruption" => %{
        "consolidationPolicy" => "WhenEmpty",
        "consolidateAfter" => "30s"
      }
    }

    :karpenter_node_pool
    |> B.build_resource()
    |> B.name("default")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end
end

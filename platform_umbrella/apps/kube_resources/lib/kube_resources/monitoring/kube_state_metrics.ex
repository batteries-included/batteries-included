defmodule KubeResources.KubeStateMetrics do
  use KubeExt.ResourceGenerator

  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B

  @app_name "kube-state-metrics"

  resource(:cluster_role_battery_kubestate_metrics) do
    B.build_resource(:cluster_role)
    |> B.name("battery-kube-state-metrics")
    |> B.app_labels(@app_name)
    |> B.rules([
      %{
        "apiGroups" => ["certificates.k8s.io"],
        "resources" => ["certificatesigningrequests"],
        "verbs" => ["list", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["configmaps"], "verbs" => ["list", "watch"]},
      %{"apiGroups" => ["batch"], "resources" => ["cronjobs"], "verbs" => ["list", "watch"]},
      %{
        "apiGroups" => ["extensions", "apps"],
        "resources" => ["daemonsets"],
        "verbs" => ["list", "watch"]
      },
      %{
        "apiGroups" => ["extensions", "apps"],
        "resources" => ["deployments"],
        "verbs" => ["list", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["endpoints"], "verbs" => ["list", "watch"]},
      %{
        "apiGroups" => ["autoscaling"],
        "resources" => ["horizontalpodautoscalers"],
        "verbs" => ["list", "watch"]
      },
      %{
        "apiGroups" => ["extensions", "networking.k8s.io"],
        "resources" => ["ingresses"],
        "verbs" => ["list", "watch"]
      },
      %{"apiGroups" => ["batch"], "resources" => ["jobs"], "verbs" => ["list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["limitranges"], "verbs" => ["list", "watch"]},
      %{
        "apiGroups" => ["admissionregistration.k8s.io"],
        "resources" => ["mutatingwebhookconfigurations"],
        "verbs" => ["list", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["namespaces"], "verbs" => ["list", "watch"]},
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["networkpolicies"],
        "verbs" => ["list", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["nodes"], "verbs" => ["list", "watch"]},
      %{
        "apiGroups" => [""],
        "resources" => ["persistentvolumeclaims"],
        "verbs" => ["list", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["persistentvolumes"], "verbs" => ["list", "watch"]},
      %{
        "apiGroups" => ["policy"],
        "resources" => ["poddisruptionbudgets"],
        "verbs" => ["list", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["pods"], "verbs" => ["list", "watch"]},
      %{
        "apiGroups" => ["extensions", "apps"],
        "resources" => ["replicasets"],
        "verbs" => ["list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["replicationcontrollers"],
        "verbs" => ["list", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["resourcequotas"], "verbs" => ["list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["services"], "verbs" => ["list", "watch"]},
      %{"apiGroups" => ["apps"], "resources" => ["statefulsets"], "verbs" => ["list", "watch"]},
      %{
        "apiGroups" => ["storage.k8s.io"],
        "resources" => ["storageclasses"],
        "verbs" => ["list", "watch"]
      },
      %{
        "apiGroups" => ["admissionregistration.k8s.io"],
        "resources" => ["validatingwebhookconfigurations"],
        "verbs" => ["list", "watch"]
      },
      %{
        "apiGroups" => ["storage.k8s.io"],
        "resources" => ["volumeattachments"],
        "verbs" => ["list", "watch"]
      }
    ])
  end

  resource(:cluster_role_binding_battery_kubestate_metrics, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("battery-kube-state-metrics")
    |> B.app_labels(@app_name)
    |> B.role_ref(B.build_cluster_role_ref("battery-kube-state-metrics"))
    |> B.subject(B.build_service_account("battery-kube-state-metrics", namespace))
  end

  resource(:deployment_battery_kubestate_metrics, battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:deployment)
    |> B.name("battery-kube-state-metrics")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "replicas" => 1,
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => @app_name
        }
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => @app_name,
            "battery/managed" => "true"
          }
        },
        "spec" => %{
          "containers" => [
            %{
              "args" => [
                "--port=8080",
                "--resources=certificatesigningrequests,configmaps,cronjobs,daemonsets,deployments,endpoints,horizontalpodautoscalers,ingresses,jobs,limitranges,mutatingwebhookconfigurations,namespaces,networkpolicies,nodes,persistentvolumeclaims,persistentvolumes,poddisruptionbudgets,pods,replicasets,replicationcontrollers,resourcequotas,secrets,services,statefulsets,storageclasses,validatingwebhookconfigurations,volumeattachments"
              ],
              "image" => battery.config.image,
              "imagePullPolicy" => "IfNotPresent",
              "livenessProbe" => %{
                "httpGet" => %{"path" => "/healthz", "port" => 8080},
                "initialDelaySeconds" => 5,
                "timeoutSeconds" => 5
              },
              "name" => "kube-state-metrics",
              "ports" => [%{"containerPort" => 8080, "name" => "http"}],
              "readinessProbe" => %{
                "httpGet" => %{"path" => "/", "port" => 8080},
                "initialDelaySeconds" => 5,
                "timeoutSeconds" => 5
              }
            }
          ],
          "hostNetwork" => false,
          "securityContext" => %{
            "fsGroup" => 65_534,
            "runAsGroup" => 65_534,
            "runAsUser" => 65_534
          },
          "serviceAccountName" => "battery-kube-state-metrics"
        }
      }
    })
  end

  resource(:service_battery_kubestate_metrics, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service)
    |> B.name("battery-kube-state-metrics")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "ports" => [%{"name" => "http", "port" => 8080, "protocol" => "TCP", "targetPort" => 8080}],
      "selector" => %{
        "battery/app" => @app_name
      },
      "type" => "ClusterIP"
    })
  end

  resource(:service_account_battery_kubestate_metrics, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> Map.put("imagePullSecrets", [])
    |> B.name("battery-kube-state-metrics")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  resource(:prometheus_rule_battery_kube_st_node_rules, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-node.rules")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "node.rules",
          "rules" => [
            %{
              "expr" =>
                "topk by(cluster, namespace, pod) (1,\n  max by (cluster, node, namespace, pod) (\n    label_replace(kube_pod_info{job=\"kube-state-metrics\",node!=\"\"}, \"pod\", \"$1\", \"pod\", \"(.*)\")\n))",
              "record" => "node_namespace_pod:kube_pod_info:"
            },
            %{
              "expr" =>
                "count by (cluster, node) (sum by (node, cpu) (\n  node_cpu_seconds_total{job=\"node-exporter\"}\n* on (namespace, pod) group_left(node)\n  topk by(namespace, pod) (1, node_namespace_pod:kube_pod_info:)\n))",
              "record" => "node:node_num_cpu:sum"
            },
            %{
              "expr" =>
                "sum(\n  node_memory_MemAvailable_bytes{job=\"node-exporter\"} or\n  (\n    node_memory_Buffers_bytes{job=\"node-exporter\"} +\n    node_memory_Cached_bytes{job=\"node-exporter\"} +\n    node_memory_MemFree_bytes{job=\"node-exporter\"} +\n    node_memory_Slab_bytes{job=\"node-exporter\"}\n  )\n) by (cluster)",
              "record" => ":node_memory_MemAvailable_bytes:sum"
            },
            %{
              "expr" =>
                "sum(rate(node_cpu_seconds_total{job=\"node-exporter\",mode!=\"idle\",mode!=\"iowait\",mode!=\"steal\"}[5m])) /\ncount(sum(node_cpu_seconds_total{job=\"node-exporter\"}) by (cluster, instance, cpu))",
              "record" => "cluster:node_cpu:ratio_rate5m"
            }
          ]
        }
      ]
    })
  end

  resource(:service_monitor_battery_kubestate_metrics, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_monitor)
    |> B.name("battery-kube-state-metrics")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "endpoints" => [%{"honorLabels" => true, "port" => "http"}],
      "jobLabel" => "battery/app",
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => @app_name
        }
      }
    })
  end
end

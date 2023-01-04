defmodule KubeResources.KubeStateMetrics do
  use KubeExt.ResourceGenerator

  import CommonCore.SystemState.Namespaces

  alias KubeExt.Builder, as: B

  @app_name "kube-state-metrics"

  resource(:cluster_role_binding_kube_state_metrics, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("kube-state-metrics")
    |> B.app_labels(@app_name)
    |> B.role_ref(B.build_cluster_role_ref("kube-state-metrics"))
    |> B.subject(B.build_service_account("kube-state-metrics", namespace))
  end

  resource(:cluster_role_kube_state_metrics) do
    rules = [
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
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resources" => ["leases"],
        "verbs" => ["list", "watch"]
      },
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
    ]

    B.build_resource(:cluster_role)
    |> B.name("kube-state-metrics")
    |> B.app_labels(@app_name)
    |> B.rules(rules)
  end

  resource(:service_account_kube_state_metrics, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> Map.put("imagePullSecrets", [])
    |> B.name("kube-state-metrics")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  resource(:deployment_kube_state_metrics, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{
          "matchLabels" => %{
            "battery/app" => @app_name
          }
        }
      )
      |> Map.put(
        "template",
        %{
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
                  "--enable-gzip-encoding",
                  "--port=8080",
                  "--resources=certificatesigningrequests,configmaps,cronjobs,daemonsets,deployments,endpoints,horizontalpodautoscalers,ingresses,jobs,leases,limitranges,mutatingwebhookconfigurations,namespaces,networkpolicies,nodes,persistentvolumeclaims,persistentvolumes,poddisruptionbudgets,pods,replicasets,replicationcontrollers,resourcequotas,secrets,services,statefulsets,storageclasses,validatingwebhookconfigurations,volumeattachments"
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
            "serviceAccountName" => "kube-state-metrics"
          }
        }
      )

    B.build_resource(:deployment)
    |> B.name("kube-state-metrics")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  resource(:monitoring_service_monitor_kube_state_metrics, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [%{"port" => "http"}])
      |> Map.put("jobLabel", "app.kubernetes.io/name")
      |> Map.put(
        "selector",
        %{
          "matchLabels" => %{
            "battery/app" => @app_name
          }
        }
      )

    B.build_resource(:monitoring_service_monitor)
    |> B.name("kube-state-metrics")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  resource(:service_kube_state_metrics, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http", "port" => 8080, "protocol" => "TCP", "targetPort" => 8080}
      ])
      |> Map.put(
        "selector",
        %{"battery/app" => @app_name}
      )

    B.build_resource(:service)
    |> B.name("kube-state-metrics")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end
end

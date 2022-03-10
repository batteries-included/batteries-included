defmodule KubeRawResources.Istio do
  @moduledoc false
  import KubeExt.Yaml

  alias KubeExt.Builder, as: B
  alias KubeRawResources.NetworkSettings

  @app_name "istio-operator"
  @crd_path "priv/manifests/istio/crd.yaml"

  def materialize(config) do
    %{}
    |> Map.put("/crd", crd(config))
    |> Map.put("/cluster_role", cluster_role(config))
    |> Map.put("/cluster_role_binding", cluster_role_binding(config))
    |> Map.put("/service_account", service_account(config))
    |> Map.put("/deployment", deployment(config))
    |> Map.put("/service", service(config))
    |> Map.put("/istio", istio(config))
    |> Map.put("/gateway", gateway(config))
  end

  def crd(_), do: yaml(crd_content())

  defp crd_content, do: unquote(File.read!(@crd_path))

  def monitors(config) do
    [pod_monitor(config), service_monitor(config)]
  end

  def pod_monitor(config) do
    namespace = NetworkSettings.namespace(config)

    spec = %{
      "selector" => %{
        "matchExpressions" => [
          %{"key" => "istio-prometheus-ignore", "operator" => "DoesNotExist"}
        ]
      },
      "namespaceSelector" => %{"any" => true},
      "jobLabel" => "envoy-stats",
      "podMetricsEndpoints" => [
        %{
          "path" => "/stats/prometheus",
          "interval" => "15s",
          "relabelings" => [
            %{
              "action" => "keep",
              "sourceLabels" => ["__meta_kubernetes_pod_container_name"],
              "regex" => "istio-proxy"
            },
            %{
              "action" => "keep",
              "sourceLabels" => ["__meta_kubernetes_pod_annotationpresent_prometheus_io_scrape"]
            },
            %{
              "sourceLabels" => [
                "__address__",
                "__meta_kubernetes_pod_annotation_prometheus_io_port"
              ],
              "action" => "replace",
              "regex" => "([^:]+)(?::\\d+)?;(\\d+)",
              "replacement" => "$1:$2",
              "targetLabel" => "__address__"
            },
            %{"action" => "labeldrop", "regex" => "__meta_kubernetes_pod_label_(.+)"},
            %{
              "sourceLabels" => ["__meta_kubernetes_namespace"],
              "action" => "replace",
              "targetLabel" => "namespace"
            },
            %{
              "sourceLabels" => ["__meta_kubernetes_pod_name"],
              "action" => "replace",
              "targetLabel" => "pod_name"
            }
          ]
        }
      ]
    }

    B.build_resource(:pod_monitor)
    |> B.name("envoy-stats-monitor")
    |> B.spec(spec)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  def service_monitor(config) do
    namespace = NetworkSettings.namespace(config)

    spec = %{
      "jobLabel" => "istio",
      "targetLabels" => ["app"],
      "selector" => %{
        "matchExpressions" => [%{"key" => "istio", "operator" => "In", "values" => ["pilot"]}]
      },
      "namespaceSelector" => %{"any" => true},
      "endpoints" => [%{"port" => "http-monitoring", "interval" => "15s"}]
    }

    B.build_resource(:service_monitor)
    |> B.name("istio-component-monitor")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> B.app_labels(@app_name)
  end

  def cluster_role(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{"name" => "battery-istio-operator"},
      "rules" => [
        %{"apiGroups" => ["authentication.istio.io"], "resources" => ["*"], "verbs" => ["*"]},
        %{"apiGroups" => ["config.istio.io"], "resources" => ["*"], "verbs" => ["*"]},
        %{"apiGroups" => ["install.istio.io"], "resources" => ["*"], "verbs" => ["*"]},
        %{"apiGroups" => ["networking.istio.io"], "resources" => ["*"], "verbs" => ["*"]},
        %{"apiGroups" => ["security.istio.io"], "resources" => ["*"], "verbs" => ["*"]},
        %{
          "apiGroups" => ["admissionregistration.k8s.io"],
          "resources" => ["mutatingwebhookconfigurations", "validatingwebhookconfigurations"],
          "verbs" => ["*"]
        },
        %{
          "apiGroups" => ["apiextensions.k8s.io"],
          "resources" => [
            "customresourcedefinitions.apiextensions.k8s.io",
            "customresourcedefinitions"
          ],
          "verbs" => ["*"]
        },
        %{
          "apiGroups" => ["apps", "extensions"],
          "resources" => ["daemonsets", "deployments", "deployments/finalizers", "replicasets"],
          "verbs" => ["*"]
        },
        %{
          "apiGroups" => ["autoscaling"],
          "resources" => ["horizontalpodautoscalers"],
          "verbs" => ["*"]
        },
        %{
          "apiGroups" => ["monitoring.coreos.com"],
          "resources" => ["servicemonitors"],
          "verbs" => ["get", "create", "update"]
        },
        %{"apiGroups" => ["policy"], "resources" => ["poddisruptionbudgets"], "verbs" => ["*"]},
        %{
          "apiGroups" => ["rbac.authorization.k8s.io"],
          "resources" => ["clusterrolebindings", "clusterroles", "roles", "rolebindings"],
          "verbs" => ["*"]
        },
        %{
          "apiGroups" => ["coordination.k8s.io"],
          "resources" => ["leases"],
          "verbs" => ["get", "create", "update"]
        },
        %{
          "apiGroups" => [""],
          "resources" => [
            "configmaps",
            "endpoints",
            "events",
            "namespaces",
            "pods",
            "pods/proxy",
            "pods/portforward",
            "persistentvolumeclaims",
            "secrets",
            "services",
            "serviceaccounts"
          ],
          "verbs" => ["*"]
        }
      ]
    }
  end

  def cluster_role_binding(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "kind" => "ClusterRoleBinding",
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "metadata" => %{"name" => "battery-istio-operator"},
      "subjects" => [
        %{"kind" => "ServiceAccount", "name" => "istio-operator", "namespace" => namespace}
      ],
      "roleRef" => %{
        "kind" => "ClusterRole",
        "name" => "battery-istio-operator",
        "apiGroup" => "rbac.authorization.k8s.io"
      }
    }
  end

  def deployment(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{"namespace" => namespace, "name" => "istio-operator"},
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{"name" => "istio-operator"}
        },
        "template" => %{
          "metadata" => %{"labels" => %{"name" => "istio-operator", "battery/managed" => "True"}},
          "spec" => %{
            "serviceAccountName" => "istio-operator",
            "containers" => [
              %{
                "name" => "istio-operator",
                "image" => "docker.io/istio/operator:1.13.1",
                "command" => ["operator", "server"],
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false,
                  "capabilities" => %{"drop" => ["ALL"]},
                  "privileged" => false,
                  "readOnlyRootFilesystem" => true,
                  "runAsGroup" => 1337,
                  "runAsUser" => 1337,
                  "runAsNonRoot" => true
                },
                "imagePullPolicy" => "IfNotPresent",
                "resources" => %{
                  "limits" => %{"cpu" => "200m", "memory" => "256Mi"},
                  "requests" => %{"cpu" => "50m", "memory" => "128Mi"}
                },
                "env" => [
                  %{
                    "name" => "WATCH_NAMESPACE",
                    "value" => Enum.join(watched_namespaces(), ",")
                  },
                  %{
                    "name" => "LEADER_ELECTION_NAMESPACE",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                  },
                  %{
                    "name" => "POD_NAME",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
                  },
                  %{"name" => "OPERATOR_NAME", "value" => "istio-operator"},
                  %{"name" => "WAIT_FOR_RESOURCES_TIMEOUT", "value" => "600s"},
                  %{"name" => "REVISION", "value" => ""}
                ]
              }
            ]
          }
        }
      }
    }
  end

  def service(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "namespace" => namespace,
        "labels" => %{"name" => "istio-operator", "battery/managed" => "True"},
        "name" => "istio-operator"
      },
      "spec" => %{
        "ports" => [
          %{"name" => "http-metrics", "port" => 8383, "targetPort" => 8383, "protocol" => "TCP"}
        ],
        "selector" => %{"name" => "istio-operator"}
      }
    }
  end

  def service_account(config) do
    namespace = NetworkSettings.namespace(config)

    B.build_resource(:service_account)
    |> B.name("istio-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  def istio(config) do
    namespace = NetworkSettings.namespace(config)

    values = %{global: %{istioNamespace: namespace}}

    spec =
      %{}
      |> Map.put("namespace", namespace)
      |> Map.put("values", values)

    B.build_resource("install.istio.io/v1alpha1", "IstioOperator")
    |> B.name("main")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  def gateway(config) do
    namespace = NetworkSettings.namespace(config)

    spec = %{
      selector: %{istio: "ingressgateway"},
      servers: [%{port: %{number: 80, name: "http", protocol: "HTTP"}, hosts: ["*"]}]
    }

    B.build_resource(:gateway)
    |> B.name("battery-gateway")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  defp watched_namespaces, do: watched_namespaces(KubeState.namespaces())

  defp watched_namespaces([] = all_namespaces) when all_namespaces == [], do: ["battery-core"]
  defp watched_namespaces(all_namespaces) do
    all_namespaces
    |> Enum.filter(fn namespace -> namespace |> K8s.Resource.name() |> String.starts_with?("battery-") end)
    |> Enum.map(fn namespace -> K8s.Resource.name(namespace) end)
    |> Enum.to_list()
  end
end

defmodule KubeResources.Kiali do
  use KubeExt.IncludeResource, config_yaml: "priv/raw_files/kiali/config.yaml"
  use KubeExt.ResourceGenerator

  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B
  alias KubeExt.FilterResource, as: F
  alias KubeExt.KubeState.Hosts
  alias KubeResources.IstioConfig.VirtualService

  @app_name "kiali"
  @url_base "/x/kiali"

  def view_url, do: view_url(KubeExt.cluster_type())

  def view_url(:dev), do: url()

  def view_url(_), do: "/services/network/kiali"

  def url, do: "http://#{Hosts.control_host()}#{@url_base}"

  resource(:virtual_service, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:istio_virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("kiali")
    |> B.spec(VirtualService.prefix(@url_base, "kiali", port: 20_001))
    |> F.require_battery(state, :istio_gateway)
  end

  resource(:cluster_role_binding_main, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("kiali")
    |> B.app_labels(@app_name)
    |> B.role_ref(B.build_cluster_role_ref("kiali"))
    |> B.subject(B.build_service_account("kiali", namespace))
  end

  resource(:cluster_role_main) do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps", "endpoints", "pods/log"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["namespaces", "pods", "replicationcontrollers", "services"],
        "verbs" => ["get", "list", "watch", "patch"]
      },
      %{"apiGroups" => [""], "resources" => ["pods/portforward"], "verbs" => ["create", "post"]},
      %{
        "apiGroups" => ["extensions", "apps"],
        "resources" => ["daemonsets", "deployments", "replicasets", "statefulsets"],
        "verbs" => ["get", "list", "watch", "patch"]
      },
      %{
        "apiGroups" => ["batch"],
        "resources" => ["cronjobs", "jobs"],
        "verbs" => ["get", "list", "watch", "patch"]
      },
      %{
        "apiGroups" => [
          "networking.istio.io",
          "security.istio.io",
          "extensions.istio.io",
          "telemetry.istio.io",
          "gateway.networking.k8s.io"
        ],
        "resources" => ["*"],
        "verbs" => ["get", "list", "watch", "create", "delete", "patch"]
      },
      %{
        "apiGroups" => ["apps.openshift.io"],
        "resources" => ["deploymentconfigs"],
        "verbs" => ["get", "list", "watch", "patch"]
      },
      %{"apiGroups" => ["project.openshift.io"], "resources" => ["projects"], "verbs" => ["get"]},
      %{"apiGroups" => ["route.openshift.io"], "resources" => ["routes"], "verbs" => ["get"]},
      %{
        "apiGroups" => ["authentication.k8s.io"],
        "resources" => ["tokenreviews"],
        "verbs" => ["create"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("kiali")
    |> B.app_labels(@app_name)
    |> B.rules(rules)
  end

  resource(:cluster_role_viewer) do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps", "endpoints", "pods/log"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["namespaces", "pods", "replicationcontrollers", "services"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["pods/portforward"], "verbs" => ["create", "post"]},
      %{
        "apiGroups" => ["extensions", "apps"],
        "resources" => ["daemonsets", "deployments", "replicasets", "statefulsets"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["batch"],
        "resources" => ["cronjobs", "jobs"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [
          "networking.istio.io",
          "security.istio.io",
          "extensions.istio.io",
          "telemetry.istio.io",
          "gateway.networking.k8s.io"
        ],
        "resources" => ["*"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["apps.openshift.io"],
        "resources" => ["deploymentconfigs"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"apiGroups" => ["project.openshift.io"], "resources" => ["projects"], "verbs" => ["get"]},
      %{"apiGroups" => ["route.openshift.io"], "resources" => ["routes"], "verbs" => ["get"]},
      %{
        "apiGroups" => ["authentication.k8s.io"],
        "resources" => ["tokenreviews"],
        "verbs" => ["create"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("kiali-viewer")
    |> B.app_labels(@app_name)
    |> B.rules(rules)
  end

  resource(:config_map_main, _battery, state) do
    namespace = istio_namespace(state)
    data = %{"config.yaml" => get_resource(:config_yaml)}

    B.build_resource(:config_map)
    |> B.name("kiali")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.data(data)
  end

  resource(:deployment_main, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "kiali"}}
      )
      |> Map.put(
        "strategy",
        %{"rollingUpdate" => %{"maxSurge" => 1, "maxUnavailable" => 1}, "type" => "RollingUpdate"}
      )
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "annotations" => %{
              "checksum/config" =>
                "c7a6b120dd3b46ca19ca89803d3c3a2f77e0657b0ba6e15985683fd35aa0f54a",
              "kiali.io/dashboards" => "go,kiali",
              "prometheus.io/port" => "9090",
              "prometheus.io/scrape" => "true"
            },
            "labels" => %{
              "battery/app" => @app_name,
              "battery/component" => "kiali",
              "battery/managed" => "true"
            },
            "name" => "kiali"
          },
          "spec" => %{
            "containers" => [
              %{
                "command" => ["/opt/kiali/kiali", "-config", "/kiali-configuration/config.yaml"],
                "env" => [
                  %{
                    "name" => "ACTIVE_NAMESPACE",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                  },
                  %{"name" => "LOG_LEVEL", "value" => "debug"},
                  %{"name" => "LOG_FORMAT", "value" => "text"},
                  %{"name" => "LOG_TIME_FIELD_FORMAT", "value" => "2006-01-02T15:04:05Z07:00"},
                  %{"name" => "LOG_SAMPLER_RATE", "value" => "1"}
                ],
                "image" => "quay.io/kiali/kiali:v1.61.0",
                "imagePullPolicy" => "Always",
                "livenessProbe" => %{
                  "httpGet" => %{
                    "path" => "/x/kiali/healthz",
                    "port" => "api-port",
                    "scheme" => "HTTP"
                  },
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 30
                },
                "name" => "kiali",
                "ports" => [
                  %{"containerPort" => 20_001, "name" => "api-port"},
                  %{"containerPort" => 9090, "name" => "http-metrics"}
                ],
                "readinessProbe" => %{
                  "httpGet" => %{
                    "path" => "/x/kiali/healthz",
                    "port" => "api-port",
                    "scheme" => "HTTP"
                  },
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 30
                },
                "resources" => %{
                  "limits" => %{"memory" => "1Gi"},
                  "requests" => %{"cpu" => "10m", "memory" => "64Mi"}
                },
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false,
                  "capabilities" => %{"drop" => ["ALL"]},
                  "privileged" => false,
                  "readOnlyRootFilesystem" => true,
                  "runAsNonRoot" => true
                },
                "volumeMounts" => [
                  %{"mountPath" => "/kiali-configuration", "name" => "kiali-configuration"},
                  %{"mountPath" => "/kiali-cert", "name" => "kiali-cert"},
                  %{"mountPath" => "/kiali-secret", "name" => "kiali-secret"},
                  %{"mountPath" => "/kiali-cabundle", "name" => "kiali-cabundle"}
                ]
              }
            ],
            "serviceAccountName" => "kiali",
            "volumes" => [
              %{"configMap" => %{"name" => "kiali"}, "name" => "kiali-configuration"},
              %{
                "name" => "kiali-cert",
                "secret" => %{"optional" => true, "secretName" => "istio.kiali-service-account"}
              },
              %{
                "name" => "kiali-secret",
                "secret" => %{"optional" => true, "secretName" => "kiali"}
              },
              %{
                "configMap" => %{"name" => "kiali-cabundle", "optional" => true},
                "name" => "kiali-cabundle"
              }
            ]
          }
        }
      )

    B.build_resource(:deployment)
    |> B.name("kiali")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  resource(:role_binding_controlplane, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:role_binding)
    |> B.name("kiali-controlplane")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.role_ref(B.build_role_ref("kiali-controlplane"))
    |> B.subject(B.build_service_account("kiali", namespace))
  end

  resource(:role_controlplane, _battery, state) do
    namespace = istio_namespace(state)

    rules = [
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["list"]},
      %{
        "apiGroups" => [""],
        "resourceNames" => ["cacerts", "istio-ca-secret"],
        "resources" => ["secrets"],
        "verbs" => ["get", "list", "watch"]
      }
    ]

    B.build_resource(:role)
    |> B.name("kiali-controlplane")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.rules(rules)
  end

  resource(:service_account_main, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:service_account)
    |> B.name("kiali")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  resource(:service_main, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http", "port" => 20_001, "protocol" => "TCP"},
        %{"name" => "http-metrics", "port" => 9090, "protocol" => "TCP"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name, "battery/component" => "kiali"})

    B.build_resource(:service)
    |> B.name("kiali")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end
end

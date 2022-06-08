defmodule KubeResources.IstioGateway do
  @moduledoc false

  alias KubeExt.Builder, as: B
  alias KubeRawResources.NetworkSettings

  @app "istio-ingressgateway"
  @istio_name "ingressgateway"

  def service_account(config) do
    namespace = NetworkSettings.istio_namespace(config)

    B.build_resource(:service_account)
    |> B.name(@istio_name)
    |> B.app_labels(@app)
    |> B.label("istio", @istio_name)
    |> B.namespace(namespace)
  end

  def telemetry(config) do
    namespace = NetworkSettings.istio_namespace(config)

    B.build_resource(:istio_telemetry)
    |> B.name("mesh-default")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{"accessLogging" => [%{"providers" => [%{"name" => "envoy"}]}]})
  end

  def role(config) do
    namespace = NetworkSettings.istio_namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "Role",
      "metadata" => %{
        "name" => @istio_name,
        "namespace" => namespace
      },
      "rules" => [
        %{
          "apiGroups" => [
            ""
          ],
          "resources" => [
            "secrets"
          ],
          "verbs" => [
            "get",
            "watch",
            "list"
          ]
        }
      ]
    }
  end

  def role_binding(config) do
    namespace = NetworkSettings.istio_namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "RoleBinding",
      "metadata" => %{
        "name" => @istio_name,
        "namespace" => namespace
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "Role",
        "name" => @istio_name
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => @istio_name
        }
      ]
    }
  end

  def service(config) do
    namespace = NetworkSettings.istio_namespace(config)

    spec = %{
      "ports" => [
        %{
          "name" => "status-port",
          "port" => 15_021,
          "protocol" => "TCP",
          "targetPort" => 15_021
        },
        %{
          "name" => "ssh",
          "port" => 22,
          "protocol" => "TCP",
          "targetPort" => 22
        },
        %{
          "name" => "http2",
          "port" => 80,
          "protocol" => "TCP",
          "targetPort" => 80
        },
        %{
          "name" => "https",
          "port" => 443,
          "protocol" => "TCP",
          "targetPort" => 443
        }
      ],
      "selector" => %{
        "istio" => @istio_name
      },
      "type" => "LoadBalancer"
    }

    B.build_resource(:service)
    |> B.app_labels(@app)
    |> B.label("istio", @istio_name)
    |> B.namespace(namespace)
    |> B.name(@istio_name)
    |> B.spec(spec)
  end

  def deployment(config) do
    namespace = NetworkSettings.istio_namespace(config)

    spec = %{
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => @app,
          "istio" => @istio_name
        }
      },
      "template" => %{
        "metadata" => %{
          "annotations" => %{
            "inject.istio.io/templates" => "gateway",
            "prometheus.io/path" => "/stats/prometheus",
            "prometheus.io/port" => "15020",
            "prometheus.io/scrape" => "true",
            "sidecar.istio.io/inject" => "true"
          },
          "labels" => %{
            "battery/app" => @app,
            "app" => @app,
            "battery/managed" => "true",
            "istio" => @istio_name,
            "sidecar.istio.io/inject" => "true"
          }
        },
        "spec" => %{
          "containers" => [
            %{
              "image" => "auto",
              "name" => "istio-proxy",
              "ports" => [
                %{
                  "containerPort" => 15_090,
                  "name" => "http-envoy-prom",
                  "protocol" => "TCP"
                }
              ],
              "resources" => %{
                "limits" => %{
                  "cpu" => "2000m",
                  "memory" => "1024Mi"
                },
                "requests" => %{
                  "cpu" => "100m",
                  "memory" => "128Mi"
                }
              },
              "securityContext" => %{
                "allowPrivilegeEscalation" => true,
                "capabilities" => %{
                  "add" => [
                    "NET_BIND_SERVICE"
                  ],
                  "drop" => [
                    "ALL"
                  ]
                },
                "readOnlyRootFilesystem" => true,
                "runAsGroup" => 1337,
                "runAsNonRoot" => false,
                "runAsUser" => 0
              }
            }
          ],
          "serviceAccountName" => @istio_name
        }
      }
    }

    B.build_resource(:deployment)
    |> B.name(@istio_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("istio", @istio_name)
    |> B.label("istio-injection", "enabled")
    |> B.spec(spec)
  end

  def horizontal_pod_autoscaler(config) do
    namespace = NetworkSettings.istio_namespace(config)

    %{
      "apiVersion" => "autoscaling/v2beta2",
      "kind" => "HorizontalPodAutoscaler",
      "metadata" => %{
        "labels" => %{
          "battery/app" => @app,
          "battery/managed" => "true",
          "istio" => @istio_name
        },
        "name" => @istio_name,
        "namespace" => namespace
      },
      "spec" => %{
        "maxReplicas" => 5,
        "metrics" => [
          %{
            "resource" => %{
              "name" => "cpu",
              "target" => %{
                "averageUtilization" => 80,
                "type" => "Utilization"
              }
            },
            "type" => "Resource"
          }
        ],
        "minReplicas" => 1,
        "scaleTargetRef" => %{
          "apiVersion" => "apps/v1",
          "kind" => "Deployment",
          "name" => @istio_name
        }
      }
    }
  end

  def gateway(config) do
    namespace = NetworkSettings.istio_namespace(config)

    spec = %{
      selector: %{istio: @istio_name},
      servers: [
        %{port: %{number: 80, name: "http", protocol: "HTTP"}, hosts: ["*"]},
        %{
          port: %{number: 22, name: "ssh", protocol: "TCP"},
          hosts: ["gitea.172.30.0.4.sslip.io"]
        }
      ]
    }

    B.build_resource(:istio_gateway)
    |> B.name(@istio_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("istio", @istio_name)
    |> B.spec(spec)
  end

  def materialize(config) do
    %{
      "/service_account" => service_account(config),
      "/role" => role(config),
      "/role_binding" => role_binding(config),
      "/service" => service(config),
      "/deployment" => deployment(config),
      "/horizontal_pod_autoscaler" => horizontal_pod_autoscaler(config),
      "/telemetry" => telemetry(config),
      "/gateway" => gateway(config)
    }
  end
end

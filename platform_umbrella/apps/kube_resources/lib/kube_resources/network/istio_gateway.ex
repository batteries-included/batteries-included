defmodule KubeResources.IstioGateway do
  @moduledoc false

  alias KubeExt.Builder, as: B
  alias KubeRawResources.NetworkSettings

  @app "istio-ingressgateway"
  @istio_name "ingressgateway"

  def namespace(config) do
    namespace_name = NetworkSettings.ingress_namespace(config)

    B.build_resource(:namespace)
    |> B.name(namespace_name)
    |> B.app_labels(@app)
    |> B.label("istio-injection", "enabled")
  end

  def service_account(config) do
    namespace = NetworkSettings.ingress_namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "labels" => %{
          "battery/app" => @app,
          "battery/managed" => "true",
          "istio" => @istio_name
        },
        "name" => "istio-ingressgateway",
        "namespace" => namespace
      }
    }
  end

  def role(config) do
    namespace = NetworkSettings.ingress_namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "Role",
      "metadata" => %{
        "name" => "istio-ingressgateway",
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
    namespace = NetworkSettings.ingress_namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "RoleBinding",
      "metadata" => %{
        "name" => "istio-ingressgateway",
        "namespace" => namespace
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "Role",
        "name" => "istio-ingressgateway"
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => "istio-ingressgateway"
        }
      ]
    }
  end

  def service(config) do
    namespace = NetworkSettings.ingress_namespace(config)

    spec = %{
      "ports" => [
        %{
          "name" => "status-port",
          "port" => 15_021,
          "protocol" => "TCP",
          "targetPort" => 15_021
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
    |> B.namespace(namespace)
    |> B.name("istio-ingressgateway")
    |> B.spec(spec)
  end

  def deployment(config) do
    namespace = NetworkSettings.ingress_namespace(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{
          "battery/app" => @app,
          "battery/managed" => "true",
          "istio" => @istio_name
        },
        "name" => "istio-ingressgateway",
        "namespace" => namespace
      },
      "spec" => %{
        "selector" => %{
          "matchLabels" => %{
            "battery/app" => @app,
            "battery/managed" => "true",
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
            "serviceAccountName" => "istio-ingressgateway"
          }
        }
      }
    }
  end

  def horizontal_pod_autoscaler(config) do
    namespace = NetworkSettings.ingress_namespace(config)

    %{
      "apiVersion" => "autoscaling/v2beta2",
      "kind" => "HorizontalPodAutoscaler",
      "metadata" => %{
        "annotations" => %{},
        "labels" => %{
          "battery/app" => @app,
          "battery/managed" => "true",
          "istio" => @istio_name
        },
        "name" => "istio-ingressgateway",
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
          "name" => "istio-ingressgateway"
        }
      }
    }
  end

  def gateway(config) do
    namespace = NetworkSettings.ingress_namespace(config)

    spec = %{
      selector: %{istio: "ingressgateway"},
      servers: [%{port: %{number: 80, name: "http", protocol: "HTTP"}, hosts: ["*"]}]
    }

    B.build_resource(:gateway)
    |> B.name("battery-gateway")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(spec)
  end

  def materialize(config) do
    %{
      "/namespace" => namespace(config),
      "/service_account" => service_account(config),
      "/role" => role(config),
      "/role_binding" => role_binding(config),
      "/service" => service(config),
      "/deployment" => deployment(config),
      "/horizontal_pod_autoscaler" => horizontal_pod_autoscaler(config),
      "/gateway" => gateway(config)
    }
  end
end

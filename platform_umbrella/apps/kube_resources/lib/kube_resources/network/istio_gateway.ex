defmodule KubeResources.IstioGateway do
  @moduledoc false
  use KubeExt.ResourceGenerator

  alias KubeExt.Builder, as: B
  alias KubeRawResources.NetworkSettings, as: Settings

  @app "istio-ingressgateway"
  @istio_name "ingressgateway"

  resource(:service_account_istio_ingressgateway, config) do
    namespace = Settings.istio_namespace(config)

    B.build_resource(:service_account)
    |> B.name("istio-ingressgateway")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("istio", @istio_name)
  end

  resource(:role_binding_istio_ingressgateway, config) do
    namespace = Settings.istio_namespace(config)

    B.build_resource(:role_binding)
    |> B.name("istio-ingressgateway")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_role_ref("istio-ingressgateway"))
    |> B.subject(B.build_service_account("istio-ingressgateway", namespace))
  end

  resource(:role_istio_ingressgateway, config) do
    namespace = Settings.istio_namespace(config)

    B.build_resource(:role)
    |> B.name("istio-ingressgateway")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.rules([
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "watch", "list"]}
    ])
  end

  resource(:telemetry, config) do
    namespace = Settings.istio_namespace(config)

    B.build_resource(:istio_telemetry)
    |> B.name("mesh-default")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{"accessLogging" => [%{"providers" => [%{"name" => "envoy"}]}]})
  end

  resource(:horizontal_pod_autoscaler_istio_ingressgateway, config) do
    namespace = Settings.istio_namespace(config)

    B.build_resource(:horizontal_pod_autoscaler)
    |> B.name("istio-ingressgateway")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("istio", @istio_name)
    |> B.spec(%{
      "maxReplicas" => 5,
      "metrics" => [
        %{
          "resource" => %{
            "name" => "cpu",
            "target" => %{"averageUtilization" => 80, "type" => "Utilization"}
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
    })
  end

  resource(:service, config) do
    namespace = Settings.istio_namespace(config)

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
        "battery/app" => @app,
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

  resource(:deployment, config) do
    namespace = Settings.istio_namespace(config)

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
          "serviceAccountName" => "istio-ingressgateway"
        }
      }
    }

    B.build_resource(:deployment)
    |> B.name("istio-ingressgateway")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("istio", @istio_name)
    |> B.label("istio-injection", "enabled")
    |> B.spec(spec)
  end

  resource(:gateway, config) do
    namespace = Settings.istio_namespace(config)

    spec = %{
      selector: %{istio: @istio_name},
      servers: [
        %{port: %{number: 80, name: "http2", protocol: "HTTP"}, hosts: ["*"]},
        %{port: %{number: 443, name: "https", protocol: "HTTPS"}, hosts: ["*"]},
        %{port: %{number: 22, name: "ssh", protocol: "TCP"}, hosts: ["*"]}
      ]
    }

    B.build_resource(:istio_gateway)
    |> B.name(@istio_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("istio", @istio_name)
    |> B.spec(spec)
  end
end

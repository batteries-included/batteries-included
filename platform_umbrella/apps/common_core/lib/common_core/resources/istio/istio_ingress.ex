defmodule CommonCore.Resources.IstioIngress do
  use CommonCore.Resources.ResourceGenerator, app_name: "istio-ingress"
  import CommonCore.StateSummary.Namespaces
  alias CommonCore.Resources.Builder, as: B

  resource(:service_account_istio_ingress, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:service_account)
    |> B.name("istio-ingress")
    |> B.namespace(namespace)
    |> B.label("istio", "ingress")
  end

  resource(:role_istio_ingress, _battery, state) do
    namespace = istio_namespace(state)

    rules = [
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "watch", "list"]}
    ]

    B.build_resource(:role)
    |> B.name("istio-ingress")
    |> B.namespace(namespace)
    |> B.label("istio", "ingress")
    |> B.rules(rules)
  end

  resource(:role_binding_istio_ingress, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:role_binding)
    |> B.name("istio-ingress")
    |> B.namespace(namespace)
    |> B.label("istio", "ingress")
    |> B.role_ref(B.build_role_ref("istio-ingress"))
    |> B.subject(B.build_service_account("istio-ingress", namespace))
  end

  resource(:service_istio_ingress, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "status-port", "port" => 15_021, "protocol" => "TCP", "targetPort" => 15_021},
        %{"name" => "http2", "port" => 80, "protocol" => "TCP", "targetPort" => 80},
        %{"name" => "https", "port" => 443, "protocol" => "TCP", "targetPort" => 443}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name, "istio" => "ingress"})
      |> Map.put("type", "LoadBalancer")

    B.build_resource(:service)
    |> B.name("istio-ingress")
    |> B.namespace(namespace)
    |> B.label("istio", "ingress")
    |> B.spec(spec)
  end

  resource(:deployment_istio_ingress, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "istio" => "ingress"}}
      )
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "annotations" => %{
              "inject.istio.io/templates" => "gateway",
              "prometheus.io/path" => "/stats/prometheus",
              "prometheus.io/port" => "15020",
              "prometheus.io/scrape" => "true",
              "sidecar.istio.io/inject" => "true"
            },
            "labels" => %{
              "battery/app" => @app_name,
              "battery/managed" => "true",
              "istio" => "ingress",
              "sidecar.istio.io/inject" => "true"
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "env" => nil,
                "image" => "auto",
                "name" => "istio-proxy",
                "ports" => [
                  %{"containerPort" => 15_090, "name" => "http-envoy-prom", "protocol" => "TCP"}
                ],
                "resources" => %{
                  "limits" => %{"cpu" => "2000m", "memory" => "1024Mi"},
                  "requests" => %{"cpu" => "100m", "memory" => "128Mi"}
                },
                "securityContext" => %{
                  "allowPrivilegeEscalation" => true,
                  "capabilities" => %{"add" => ["NET_BIND_SERVICE"], "drop" => ["ALL"]},
                  "readOnlyRootFilesystem" => true,
                  "runAsGroup" => 1337,
                  "runAsNonRoot" => false,
                  "runAsUser" => 0
                }
              }
            ],
            "securityContext" => nil,
            "serviceAccountName" => "istio-ingress"
          }
        }
      )

    B.build_resource(:deployment)
    |> B.name("istio-ingress")
    |> B.namespace(namespace)
    |> B.label("istio", "ingress")
    |> B.spec(spec)
  end

  resource(:horizontal_pod_autoscaler_istio_ingress, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("maxReplicas", 5)
      |> Map.put("metrics", [
        %{
          "resource" => %{
            "name" => "cpu",
            "target" => %{"averageUtilization" => 80, "type" => "Utilization"}
          },
          "type" => "Resource"
        }
      ])
      |> Map.put("minReplicas", 1)
      |> Map.put(
        "scaleTargetRef",
        %{"apiVersion" => "apps/v1", "kind" => "Deployment", "name" => "istio-ingress"}
      )

    B.build_resource(:horizontal_pod_autoscaler)
    |> B.name("istio-ingress")
    |> B.namespace(namespace)
    |> B.label("istio", "ingress")
    |> B.spec(spec)
  end

  resource(:gateway, _battery, state) do
    namespace = istio_namespace(state)

    spec = %{
      selector: %{istio: "ingress"},
      servers: [
        %{port: %{number: 80, name: "http2", protocol: "HTTP"}, hosts: ["*"]},
        # %{port: %{number: 443, name: "https", protocol: "HTTPS"}, hosts: ["*"]},
        %{port: %{number: 22, name: "ssh", protocol: "TCP"}, hosts: ["*"]}
      ]
    }

    B.build_resource(:istio_gateway)
    |> B.name("ingress")
    |> B.namespace(namespace)
    |> B.label("istio", "ingress")
    |> B.spec(spec)
  end

  resource(:telemetry, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:istio_telemetry)
    |> B.name("mesh-default")
    |> B.namespace(namespace)
    |> B.spec(%{"accessLogging" => [%{"providers" => [%{"name" => "envoy"}]}]})
  end
end

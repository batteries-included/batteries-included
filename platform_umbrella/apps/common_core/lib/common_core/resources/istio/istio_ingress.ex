defmodule CommonCore.Resources.Istio.IngressGateway do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "istio-ingressgateway"

  import CommonCore.StateSummary.Namespaces
  import CommonCore.Util.Map

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.StateSummary.Batteries
  alias CommonCore.StateSummary.Core

  resource(:service_ingressgateway, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "status-port", "port" => 15_021, "protocol" => "TCP", "targetPort" => 15_021},
        %{"name" => "http2", "port" => 80, "protocol" => "TCP", "targetPort" => 80},
        %{"name" => "https", "port" => 443, "protocol" => "TCP", "targetPort" => 443}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name, "istio" => "ingressgateway"})
      |> Map.put("type", "LoadBalancer")

    :service
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.label("istio", "ingressgateway")
    |> B.spec(spec)
    |> add_public_lb_annotations(state)
  end

  defp add_public_lb_annotations(config, state) do
    aws_lb_installed? = Batteries.batteries_installed?(state, :aws_load_balancer_controller)
    cluster_name = Core.config_field(state, :cluster_name)

    annotations =
      if aws_lb_installed? do
        battery = Batteries.by_type(state).aws_load_balancer_controller

        tags =
          Enum.join(
            [
              "batteriesincl.com/managed=true",
              "batteriesincl.com/environment=organization/bi/#{cluster_name}"
            ],
            ","
          )

        %{
          "service.beta.kubernetes.io/aws-load-balancer-scheme" => "internet-facing",
          # the advantage of the AWS VPC CNI is that each pod has an IP, use those instead of the instances
          # the controller will make sure that the LB is updated as pods come and go
          "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" => "ip",
          "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" => "true",
          "service.beta.kubernetes.io/aws-load-balancer-name" => "#{cluster_name}-ingress",
          "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" => tags
        }
        |> maybe_put_lazy(
          battery.config.subnets != nil,
          "service.beta.kubernetes.io/aws-load-balancer-subnets",
          fn _ -> battery.config.subnets |> Enum.sort() |> Enum.join(",") end
        )
        |> maybe_put_lazy(
          battery.config.eip_allocations != nil,
          "service.beta.kubernetes.io/aws-load-balancer-eip-allocations",
          fn _ -> battery.config.eip_allocations |> Enum.sort() |> Enum.join(",") end
        )
      else
        %{}
      end

    B.annotations(config, annotations)
  end

  resource(:service_account_istio_ingress, _battery, state) do
    namespace = istio_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.label("istio", "ingressgateway")
  end

  resource(:role_istio_ingressgateway, _battery, state) do
    namespace = istio_namespace(state)

    rules = [
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "watch", "list"]}
    ]

    :role
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.label("istio", "ingressingressgateway")
    |> B.rules(rules)
  end

  resource(:role_binding_istio_ingressgateway, _battery, state) do
    namespace = istio_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.label("istio", "ingressgateway")
    |> B.role_ref(B.build_role_ref(@app_name))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:deployment_istio_ingress, battery, state) do
    namespace = istio_namespace(state)

    template =
      %{}
      |> Map.put("metadata", %{
        "annotations" => %{
          "inject.istio.io/templates" => "gateway",
          "prometheus.io/path" => "/stats/prometheus",
          "prometheus.io/port" => "15020",
          "prometheus.io/scrape" => "true",
          "sidecar.istio.io/inject" => "true"
        },
        "labels" => %{
          "battery/managed" => "true",
          "istio" => "ingressgateway",
          "service.istio.io/canonical-name" => @app_name,
          "service.istio.io/canonical-revision" => "latest",
          "sidecar.istio.io/inject" => "true"
        }
      })
      |> Map.put("spec", %{
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
              "allowPrivilegeEscalation" => false,
              "capabilities" => %{"drop" => ["ALL"]},
              "privileged" => false,
              "readOnlyRootFilesystem" => true,
              "runAsGroup" => 1337,
              "runAsNonRoot" => true,
              "runAsUser" => 1337
            }
          }
        ],
        "securityContext" => %{
          "sysctls" => [%{"name" => "net.ipv4.ip_unprivileged_port_start", "value" => "0"}]
        },
        "serviceAccountName" => @app_name,
        "terminationGracePeriodSeconds" => 30
      })
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name, "istio" => "ingressgateway"}})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.label("istio", "ingressgateway")
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
      |> Map.put("scaleTargetRef", %{
        "apiVersion" => "apps/v1",
        "kind" => "Deployment",
        "name" => @app_name
      })

    :horizontal_pod_autoscaler
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.label("istio", "ingressgateway")
    |> B.spec(spec)
  end
end

defmodule CommonCore.Resources.Istio.Ingress do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "istio-ingress"

  import CommonCore.StateSummary.Namespaces
  import CommonCore.Util.Map

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.StateSummary.Batteries
  alias CommonCore.StateSummary.Core

  resource(:service_ingress, _battery, state) do
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

    :service
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.label("istio", "ingress")
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

  resource(:gateway_ingress, _battery, state) do
    namespace = istio_namespace(state)

    # styler:sort
    spec = %{
      "addresses" => [
        # the manually created service above
        %{"type" => "Hostname", "value" => "#{@app_name}.#{namespace}.svc.cluster.local"}
      ],
      "gatewayClassName" => "istio",
      "infrastructure" => %{},
      "listeners" => [
        %{
          "name" => "http",
          "port" => 80,
          "protocol" => "HTTP",
          "allowedRoutes" => %{"namespaces" => %{"from" => "All"}}
        }
      ]
    }

    :gateway
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:role_ingress_sds, _battery, state) do
    namespace = istio_namespace(state)

    rules = [
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "watch", "list"]}
    ]

    :role
    |> B.build_resource()
    |> B.name("istio-ingress-sds")
    |> B.namespace(namespace)
    |> B.label("istio.io/rev", "default")
    |> B.label("istio", "ingress")
    |> B.rules(rules)
  end

  resource(:role_binding_ingress_sds, _battery, state) do
    namespace = istio_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("istio-ingress-sds")
    |> B.namespace(namespace)
    |> B.label("istio", "ingress")
    |> B.label("istio.io/rev", "default")
    |> B.role_ref(B.build_role_ref("istio-ingress-sds"))
    |> B.subject(B.build_service_account("istio-ingress-service-account", namespace))
  end

  resource(:deployment_ingress, battery, state) do
    namespace = istio_namespace(state)

    template =
      %{
        "spec" => %{
          "containers" => [
            %{
              "name" => "istio-proxy",
              "image" => "auto",
              "securityContext" => %{"capabilities" => %{"drop" => ["ALL"]}, "runAsUser" => 1337, "runAsGroup" => 1337}
            }
          ],
          "securityContext" => %{"sysctls" => [%{"name" => "net.ipv4.ip_unprivileged_port_start", "value" => "0"}]}
        }
      }
      |> B.annotation("inject.istio.io/templates", "gateway")
      |> B.label("sidecar.istio.io/inject", "true")
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name, "istio" => "ingress"}})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("istio-ingress")
    |> B.namespace(namespace)
    |> B.label("istio", "ingress")
    |> B.label("istio.io/rev", "default")
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
        "name" => "#{@app_name}-istio"
      })

    :horizontal_pod_autoscaler
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.label("istio", "ingress")
    |> B.spec(spec)
  end
end

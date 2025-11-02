defmodule CommonCore.Resources.Istio.Ingress do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "istio-ingressgateway"

  import CommonCore.StateSummary.Namespaces
  import CommonCore.Util.Map
  import CommonCore.Util.String

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.RouteBuilder
  alias CommonCore.StateSummary.Batteries
  alias CommonCore.StateSummary.Core
  alias CommonCore.StateSummary.SSL

  resource(:service_ingress, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "ssh", "port" => 2202, "protocol" => "TCP", "targetPort" => 2202},
        %{"name" => "http2", "port" => 80, "protocol" => "TCP", "targetPort" => 8080},
        %{"name" => "https", "port" => 443, "protocol" => "TCP", "targetPort" => 8443}
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
      "listeners" =>
        [
          %{
            "name" => "ssh",
            "port" => 2202,
            "protocol" => "TCP",
            "allowedRoutes" => %{"namespaces" => %{"from" => "All"}}
          },
          %{
            "name" => "http",
            "port" => 80,
            "protocol" => "HTTP",
            "allowedRoutes" => %{"namespaces" => %{"from" => "All"}}
          }
        ] ++ https_listeners(state)
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
    |> B.name("istio-ingressgateway-sds")
    |> B.namespace(namespace)
    |> B.label("istio.io/rev", "default")
    |> B.label("istio", "ingressgateway")
    |> B.rules(rules)
  end

  resource(:role_binding_ingress_sds, _battery, state) do
    namespace = istio_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("istio-ingressgateway-sds")
    |> B.namespace(namespace)
    |> B.label("istio", "ingressgateway")
    |> B.label("istio.io/rev", "default")
    |> B.role_ref(B.build_role_ref("istio-ingressgateway-sds"))
    |> B.subject(B.build_service_account("istio-ingressgateway-service-account", namespace))
  end

  resource(:service_account_ingress, _battery, state) do
    namespace = istio_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name("istio-ingressgateway-service-account")
    |> B.namespace(namespace)
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
              "securityContext" => %{
                "capabilities" => %{"drop" => ["ALL"]},
                "runAsUser" => 1337,
                "runAsGroup" => 1337
              },
              "ports" => [
                %{"containerPort" => 15_021, "protocol" => "TCP"},
                %{"containerPort" => 2202, "protocol" => "TCP"},
                %{"containerPort" => 8080, "protocol" => "TCP"},
                %{"containerPort" => 8443, "protocol" => "TCP"},
                %{"containerPort" => 15_090, "name" => "http-envoy-prom", "protocol" => "TCP"}
              ]
            }
          ],
          "securityContext" => %{
            "sysctls" => [%{"name" => "net.ipv4.ip_unprivileged_port_start", "value" => "0"}]
          }
        }
      }
      |> B.annotation("inject.istio.io/templates", "gateway")
      |> B.label("sidecar.istio.io/inject", "true")
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("selector", %{
        "matchLabels" => %{"battery/app" => @app_name, "istio" => "ingressgateway"}
      })
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("istio-ingressgateway")
    |> B.namespace(namespace)
    |> B.label("istio", "ingressgateway")
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
    |> B.label("istio", "ingressgateway")
    |> B.spec(spec)
  end

  # create an httproute for each battery that redirects to https if ssl enabled
  multi_resource(:httproute_http_redirect, _battery, state) do
    namespace = istio_namespace(state)

    state
    |> Batteries.hosts_by_battery_type()
    |> Enum.map(fn {type, hosts} ->
      name = kebab_case(type)

      spec = %{
        "hostnames" => hosts,
        "parentRefs" => [%{"name" => "istio-ingressgateway", "sectionName" => "http"}],
        "rules" => [
          %{
            "filters" => [
              %{
                "type" => "RequestRedirect",
                "requestRedirect" => %{"scheme" => "https", "statusCode" => 301}
              }
            ]
          }
        ]
      }

      :gateway_http_route
      |> B.build_resource()
      |> B.name("http-redirect-#{name}")
      |> B.namespace(namespace)
      |> B.spec(spec)
      |> F.require(SSL.ssl_enabled?(state))
      |> F.require_non_empty(hosts)
      |> F.require(RouteBuilder.valid?(spec))
    end)
  end

  defp https_listeners(state) do
    state
    |> Batteries.hosts_by_battery_type()
    |> Enum.reject(fn {_type, hosts} -> hosts == nil || hosts == [] end)
    |> Enum.flat_map(fn {type, hosts} ->
      hosts
      |> Enum.with_index()
      |> Enum.map(fn {host, ix} ->
        %{
          "name" => "https-#{kebab_case(type)}-#{ix}",
          "hostname" => host,
          "port" => 443,
          "protocol" => "HTTPS",
          "tls" => %{
            "mode" => "Terminate",
            "certificateRefs" => [%{"name" => "#{kebab_case(type)}-ingress-cert"}]
          },
          "allowedRoutes" => %{"namespaces" => %{"from" => "All"}}
        }
      end)
    end)
    |> Enum.sort_by(&Map.get(&1, "name"))
  end
end

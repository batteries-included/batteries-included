defmodule CommonCore.Resources.VMAgent do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "vm_agent"

  import CommonCore.StateSummary.Hosts
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.ProxyUtils, as: PU
  alias CommonCore.Resources.RouteBuilder, as: R

  @vm_agent_port 8429
  @instance_name "main-agent"
  @k8s_name "vmagent"

  resource(:vm_agent_main, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("extraArgs", %{"promscrape.streamParse" => "true"})
      |> Map.put("image", %{"tag" => battery.config.image_tag})
      |> Map.put("remoteWrite", [
        %{
          "url" => "http://vminsert-main-cluster.#{namespace}.svc.cluster.local.:8480/insert/0/prometheus/api/v1/write"
        }
      ])
      |> Map.put("scrapeInterval", "10s")
      |> Map.put("selectAllByDefault", true)

    :vm_agent
    |> B.build_resource()
    |> B.name(@instance_name)
    |> B.namespace(namespace)
    |> B.label("istio.io/ingress-use-waypoint", "true")
    |> B.spec(spec)
  end

  resource(:http_route, battery, state) do
    namespace = core_namespace(state)

    spec =
      battery
      |> R.new_httproute_spec(state)
      |> R.add_oauth2_proxy_rule(battery, state)
      |> R.add_backend("vmagent-main-agent", @vm_agent_port)

    :gateway_http_route
    |> B.build_resource()
    |> B.name(@k8s_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
    |> F.require(R.valid?(spec))
  end

  resource(:istio_request_auth, _battery, state) do
    namespace = core_namespace(state)

    spec =
      state
      |> PU.request_auth()
      |> PU.target_ref_for_service("vmagent-main-agent")

    :istio_request_auth
    |> B.build_resource()
    |> B.name("#{@k8s_name}-keycloak-auth-gw")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :sso)
  end

  resource(:istio_auth_policy, battery, state) do
    namespace = core_namespace(state)

    spec =
      state
      |> vmagent_hosts()
      |> PU.auth_policy(battery)
      |> PU.target_ref_for_service("vmagent-main-agent")

    :istio_auth_policy
    |> B.build_resource()
    |> B.name("#{@k8s_name}-require-keycloak-auth-gw")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :sso)
  end
end

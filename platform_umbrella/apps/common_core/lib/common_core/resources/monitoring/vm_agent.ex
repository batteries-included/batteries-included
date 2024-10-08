defmodule CommonCore.Resources.VMAgent do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "vm_agent"

  import CommonCore.StateSummary.Hosts
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.OpenAPI.IstioVirtualService.VirtualService
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.ProxyUtils, as: PU
  alias CommonCore.Resources.VirtualServiceBuilder, as: V

  @vm_agent_port 8429
  @instance_name "main-agent"
  @k8s_name "vmagent"

  resource(:vm_agent_main, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("externalLabels", %{"cluster" => "cluster-name"})
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
    |> B.spec(spec)
  end

  resource(:virtual_service, battery, state) do
    namespace = core_namespace(state)

    spec =
      [hosts: vmagent_hosts(state)]
      |> VirtualService.new!()
      |> V.prefix(PU.prefix(battery), PU.service_name(battery), PU.port(battery))
      |> V.fallback("vmagent-main-agent", @vm_agent_port)

    :istio_virtual_service
    |> B.build_resource()
    |> B.name(@k8s_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
  end

  resource(:istio_request_auth, _battery, state) do
    namespace = core_namespace(state)

    spec =
      state
      |> PU.request_auth()
      |> B.match_labels_selector("app.kubernetes.io/name", @k8s_name)
      |> B.match_labels_selector("app.kubernetes.io/instance", @instance_name)

    :istio_request_auth
    |> B.build_resource()
    |> B.name("#{@k8s_name}-keycloak-auth")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :sso)
  end

  resource(:istio_auth_policy, battery, state) do
    namespace = core_namespace(state)

    spec =
      state
      |> vmagent_host()
      |> List.wrap()
      |> PU.auth_policy(battery)
      |> B.match_labels_selector("app.kubernetes.io/name", @k8s_name)
      |> B.match_labels_selector("app.kubernetes.io/instance", @instance_name)

    :istio_auth_policy
    |> B.build_resource()
    |> B.name("#{@k8s_name}-require-keycloak-auth")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :sso)
  end
end

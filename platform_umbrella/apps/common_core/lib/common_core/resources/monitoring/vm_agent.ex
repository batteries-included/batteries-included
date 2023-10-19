defmodule CommonCore.Resources.VMAgent do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "vm_agent"

  import CommonCore.StateSummary.Hosts
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.OpenApi.IstioVirtualService.VirtualService
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.VirtualServiceBuilder, as: V

  @web_port 80

  resource(:vm_agent_main, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("externalLabels", %{"cluster" => "cluster-name"})
      |> Map.put("extraArgs", %{"promscrape.streamParse" => "true"})
      |> Map.put("image", %{"tag" => battery.config.image_tag})
      |> Map.put("remoteWrite", [
        %{
          "url" => "http://vminsert-main-cluster.#{namespace}.svc:8480/insert/0/prometheus/api/v1/write"
        }
      ])
      |> Map.put("scrapeInterval", "25s")
      |> Map.put("selectAllByDefault", true)

    :vm_agent
    |> B.build_resource()
    |> B.name("main-agent")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:virtual_service, _battery, state) do
    namespace = core_namespace(state)

    spec =
      [hosts: [vmagent_host(state)]]
      |> VirtualService.new!()
      |> V.fallback("vmagent-main-agent", @web_port)

    :istio_virtual_service
    |> B.build_resource()
    |> B.name("vmagent")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
  end
end

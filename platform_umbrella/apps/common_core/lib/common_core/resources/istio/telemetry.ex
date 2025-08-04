defmodule CommonCore.Resources.Istio.Telemetry do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "istio-telemetry"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B

  resource(:telemetry, _battery, state) do
    namespace = istio_namespace(state)

    :istio_telemetry
    |> B.build_resource()
    |> B.name("mesh-default")
    |> B.namespace(namespace)
    |> B.spec(%{
      "accessLogging" => [%{"providers" => [%{"name" => "envoy"}]}],
      "metrics" => [%{"providers" => [%{"name" => "prometheus"}]}]
    })
  end
end

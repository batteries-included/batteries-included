defmodule CommonCore.Resources.Istio.Namespace do
  @moduledoc false

  use CommonCore.Resources.ResourceGenerator, app_name: "istio-namespace"

  alias CommonCore.Resources.Builder, as: B

  resource(:istio_namespace, battery, _state) do
    :namespace
    |> B.build_resource()
    |> B.name(battery.config.namespace)
    |> B.label("istio-injection", "enabled")
  end
end

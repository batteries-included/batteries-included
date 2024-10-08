defmodule CommonCore.Resources.BatteryAccess do
  @moduledoc false

  use CommonCore.Resources.ResourceGenerator, app_name: "battery-access-info"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.StateSummary.AccessSpec

  resource(:info_configmap, _battery, state) do
    case AccessSpec.new(state) do
      {:ok, spec} ->
        :config_map
        |> B.build_resource()
        |> B.name("access-info")
        |> B.namespace(core_namespace(state))
        |> B.data(AccessSpec.to_data(spec))

      {:error, _} ->
        nil
    end
  end
end

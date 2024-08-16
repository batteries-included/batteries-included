defmodule CommonCore.Resources.Bootstrap.TraditionalServices do
  @moduledoc false

  use CommonCore.Resources.ResourceGenerator, app_name: "traditional-services"

  # import CommonCore.Resources.StorageClass
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.StateSummary.Core

  resource(:namespace, battery, _state) do
    :namespace
    |> B.build_resource()
    |> B.name(battery.config.namespace)
    |> B.label("istio-injection", "enabled")
  end

  resource(:config_map_homebase, battery, state) do
    usage = Core.config_field(state, :usage)
    data = home_base_data(usage)

    :config_map
    |> B.build_resource()
    |> B.name("home-base-specs")
    |> B.namespace(battery.config.namespace)
    |> B.data(data)
    |> F.require_non_empty(data)
  end

  defp home_base_data(usage) when usage in [:internal_prod] do
    path = "../bootstrap"

    path
    |> File.ls!()
    |> Map.new(fn file_name -> {file_name, File.read!(Path.join(path, file_name))} end)
  end

  defp home_base_data(_usage), do: %{}
end

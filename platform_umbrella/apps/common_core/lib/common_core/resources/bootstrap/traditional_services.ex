defmodule CommonCore.Resources.Bootstrap.TraditionalServices do
  @moduledoc false

  use CommonCore.Resources.ResourceGenerator, app_name: "traditional-services"

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
    data = home_base_data(usage, state)

    :config_map
    |> B.build_resource()
    |> B.name("home-base-seed-data")
    |> B.namespace(battery.config.namespace)
    # wait 45 minutes to delete
    |> B.label("battery/delete-after", "PT45M")
    |> B.data(data)
    |> F.require_non_empty(data)
  end

  defp home_base_data(usage, state) when usage in [:internal_int_test, :internal_prod] do
    installs =
      Enum.map(state.home_base_init_data.installs, fn install -> {"#{install.slug}.install.json", to_json!(install)} end)

    teams = Enum.map(state.home_base_init_data.teams, fn team -> {"#{team.id}.team.json", to_json!(team)} end)

    Map.new(installs ++ teams)
  end

  defp home_base_data(_usage, _state), do: %{}

  defp to_json!(data), do: Jason.encode!(data, pretty: false, escape: :javascript_safe)
end

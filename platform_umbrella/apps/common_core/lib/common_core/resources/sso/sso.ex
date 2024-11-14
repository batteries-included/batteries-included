defmodule CommonCore.Resources.SSO do
  @moduledoc false
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Resources.Oauth2Proxy
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Batteries

  @proxy_enabled_batteries ~w[notebooks smtp4dev vm_agent victoria_metrics]a

  def proxy_enabled_batteries, do: @proxy_enabled_batteries

  def materialize(%SystemBattery{} = _battery, %StateSummary{} = state) do
    state
    |> Batteries.by_type()
    |> Enum.filter(fn {type, _battery} -> type in @proxy_enabled_batteries end)
    |> Enum.map(fn {_type, battery} -> Oauth2Proxy.materialize(battery, state) end)
    |> Enum.reduce(%{}, &Map.merge/2)
  end
end

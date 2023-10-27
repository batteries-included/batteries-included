defmodule CommonCore.Resources.SSO do
  @moduledoc false
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Resources.Oauth2Proxy
  alias CommonCore.StateSummary

  @proxy_enabled_batteries ~w[smtp4dev vm_agent vm_cluster]a

  def proxy_enabled_batteries, do: @proxy_enabled_batteries

  def materialize(%SystemBattery{} = _battery, %StateSummary{batteries: batteries} = state) do
    batteries
    |> batteries_by_type()
    |> Enum.reject(fn {type, _battery} -> type not in @proxy_enabled_batteries end)
    |> Enum.map(fn {_type, battery} -> Oauth2Proxy.materialize(battery, state) end)
    |> Enum.reduce(%{}, &Map.merge/2)
  end

  defp batteries_by_type(batteries) do
    Enum.reduce(batteries, %{}, fn battery, acc -> Map.merge(acc, %{battery.type => battery}) end)
  end
end

defmodule CommonCore.Resources.ProxyUtils do
  @moduledoc false
  use TypedStruct

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.StateSummary

  require Logger

  @default_port 80

  @spec port(SystemBattery.t(), StateSummary.t()) :: pos_integer()
  def port(_battery, _state) do
    @default_port
  end

  @spec extension_name(SystemBattery.t(), StateSummary.t()) :: String.t()
  def extension_name(%SystemBattery{type: battery_type} = _battery, %StateSummary{} = _state) do
    "#{battery_type |> Atom.to_string() |> sanitize()}-ext-authz-http"
  end

  @spec service_name(SystemBattery.t(), StateSummary.t()) :: String.t()
  def service_name(%SystemBattery{type: battery_type} = _battery, %StateSummary{} = _state) do
    "oauth2-proxy-#{battery_type |> Atom.to_string() |> sanitize()}"
  end

  @spec fully_qualified_service_name(SystemBattery.t(), StateSummary.t()) :: String.t()
  def fully_qualified_service_name(%SystemBattery{} = battery, %StateSummary{} = state) do
    svc = service_name(battery, state)
    namespace = core_namespace(state)
    "#{svc}.#{namespace}.svc.cluster.local"
  end

  @spec prefix(SystemBattery.t(), StateSummary.t()) :: String.t()
  def prefix(%SystemBattery{} = _battery, %StateSummary{} = _state) do
    "/oauth2"
  end

  @spec cookie_secret(SystemBattery.t(), StateSummary.t()) :: String.t()
  def cookie_secret(%SystemBattery{config: battery_config} = _battery, %StateSummary{} = _state) do
    battery_config.cookie_secret
  end

  @spec sanitize(String.t()) :: String.t()
  defp sanitize(s) do
    s
    |> String.downcase()
    |> String.replace(" ", "-")
    |> String.replace("_", "-")
  end
end

defmodule CommonCore.Resources.ProxyUtils do
  @moduledoc false
  use TypedStruct

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.StateSummary

  require Logger

  @default_port 80

  @spec port(SystemBattery.t()) :: pos_integer()
  def port(_battery) do
    @default_port
  end

  @spec extension_name(SystemBattery.t()) :: String.t()
  def extension_name(%SystemBattery{type: battery_type} = _battery) do
    "#{sanitize(battery_type)}-ext-authz-http"
  end

  def extension_name(_), do: nil

  @spec service_name(SystemBattery.t()) :: String.t()
  def service_name(%SystemBattery{type: battery_type} = _battery) do
    "oauth2-proxy-#{sanitize(battery_type)}"
  end

  def service_name(_), do: nil

  @spec fully_qualified_service_name(SystemBattery.t(), StateSummary.t()) :: String.t()
  def fully_qualified_service_name(%SystemBattery{} = battery, %StateSummary{} = state) do
    svc = service_name(battery)
    namespace = core_namespace(state)
    "#{svc}.#{namespace}.svc.cluster.local."
  end

  def fully_qualified_service_name(_, _), do: nil

  @spec prefix(SystemBattery.t()) :: String.t()
  def prefix(_) do
    "/oauth2"
  end

  @spec cookie_secret(SystemBattery.t()) :: String.t()
  def cookie_secret(%SystemBattery{config: battery_config} = _battery) do
    battery_config.cookie_secret
  end

  def cookie_secret(_), do: nil

  def auth_policy(hosts, battery) do
    %{
      "action" => "CUSTOM",
      "provider" => %{"name" => extension_name(battery)},
      "rules" => [%{"to" => [%{"operation" => %{"hosts" => hosts}}]}]
    }
  end

  def request_auth(state) do
    uri = CommonCore.StateSummary.URLs.keycloak_uri_for_realm(state, CommonCore.Defaults.Keycloak.realm_name())

    %{
      "jwtRules" => [
        %{
          "issuer" => URI.to_string(uri),
          "jwksUri" => uri |> URI.append_path("/protocol/openid-connect/certs") |> URI.to_string()
        }
      ]
    }
  end

  @spec sanitize(atom()) :: String.t()
  def sanitize(a) when is_atom(a), do: sanitize(Atom.to_string(a))

  @spec sanitize(String.t()) :: String.t()
  def sanitize(s) do
    s
    |> String.downcase()
    |> String.replace(" ", "-")
    |> String.replace("_", "-")
  end
end

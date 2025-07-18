defmodule CommonCore.Resources.ProxyUtils do
  @moduledoc false
  use TypedStruct

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Knative.Service
  alias CommonCore.OpenAPI.KeycloakAdminSchema.ClientRepresentation
  alias CommonCore.Resources.Builder
  alias CommonCore.Resources.Secret
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Batteries

  require Logger

  @default_port 80
  @web_port 4180
  @metrics_port 44_180

  @spec web_port() :: pos_integer()
  def web_port do
    @web_port
  end

  @spec metrics_port() :: pos_integer()
  def metrics_port do
    @metrics_port
  end

  @spec port(SystemBattery.t()) :: pos_integer()
  def port(_battery) do
    @default_port
  end

  @spec extension_name(SystemBattery.t()) :: String.t()
  def extension_name(%SystemBattery{type: battery_type} = _battery) do
    "#{sanitize(battery_type)}-ext-authz-http"
  end

  def extension_name(_), do: nil

  @spec service_name(SystemBattery.t() | Service.t() | atom() | String.t()) :: String.t()
  def service_name(thing)

  def service_name(%SystemBattery{type: battery_type} = _battery), do: service_name(battery_type)
  def service_name(%Service{name: name} = _service), do: service_name(name)
  def service_name(name) when is_atom(name), do: service_name(Atom.to_string(name))
  def service_name(name) when is_binary(name), do: "oauth2-proxy-#{sanitize(name)}"

  def service_name(_), do: nil

  @spec fully_qualified_service_name(SystemBattery.t(), StateSummary.t()) :: String.t()
  def fully_qualified_service_name(%SystemBattery{} = battery, %StateSummary{} = state) do
    svc = service_name(battery)
    namespace = core_namespace(state)
    "#{svc}.#{namespace}.svc.cluster.local"
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

  @spec secret_data(ClientRepresentation.t(), String.t()) :: any()
  def secret_data(%ClientRepresentation{clientId: client_id, secret: client_secret}, cookie_secret) do
    Secret.encode(%{
      "client-id" => client_id,
      "client-secret" => client_secret,
      "cookie-secret" => cookie_secret
    })
  end

  @spec deployment_env(map()) :: list(map())
  def deployment_env(%{secret_name: secret_name, redirect_url: redirect_url, keycloak_url: keycloak_url}) do
    [
      %{"name" => to_env_var("oidc-issuer-url"), "value" => keycloak_url},
      %{"name" => to_env_var("redirect-url"), "value" => redirect_url},
      %{
        "name" => to_env_var("client-id"),
        "valueFrom" => Builder.secret_key_ref(secret_name, "client-id")
      },
      %{
        "name" => to_env_var("client-secret"),
        "valueFrom" => Builder.secret_key_ref(secret_name, "client-secret")
      },
      %{
        "name" => to_env_var("cookie-secret"),
        "valueFrom" => Builder.secret_key_ref(secret_name, "cookie-secret")
      }
    ]
  end

  defp to_env_var(s) do
    "OAUTH2_PROXY_#{s}"
    |> String.upcase()
    |> String.replace(" ", "_")
    |> String.replace("-", "_")
  end

  def deployment_args(upstream) do
    [
      "--http-address=0.0.0.0:#{@web_port}",
      "--metrics-address=0.0.0.0:#{@metrics_port}",
      "--email-domain=*",
      "--upstream=#{upstream}",
      "--auth-logging=true",
      "--code-challenge-method=S256",
      "--cookie-expire=4h",
      "--cookie-httponly=true",
      "--cookie-refresh=4m",
      "--cookie-samesite=lax",
      "--cookie-secure=false",
      "--pass-access-token=true",
      "--pass-authorization-header=true",
      "--pass-host-header=true",
      "--provider=oidc",
      "--request-logging=true",
      "--reverse-proxy=true",
      "--scope=openid email profile",
      "--session-store-type=cookie",
      "--set-authorization-header=true",
      "--set-xauthrequest=true",
      "--silence-ping-logging=true",
      "--skip-auth-strip-headers=false",
      "--skip-jwt-bearer-tokens=true",
      "--skip-provider-button=true",
      "--ssl-insecure-skip-verify=true",
      "--insecure-oidc-allow-unverified-email=true",
      "--standard-logging=true",
      "--skip-auth-route=\"/healthz\"",
      "--skip-auth-route=\"/ping\"",
      "--exclude-logging-path=\"healthz\"",
      "--exclude-logging-path=\"ping\""
    ]
  end

  @spec deployment_image(StateSummary.t()) :: String.t() | nil
  def deployment_image(state) do
    if Batteries.sso_installed?(state) do
      Batteries.by_type(state).sso.config.oauth2_proxy_image
    end
  end

  def target_ref_for_service(spec, name), do: target_refs_for_services(spec, [name])

  def target_refs_for_services(spec, names) do
    Map.put(spec, "targetRefs", Enum.map(names, &%{"name" => &1, "kind" => "Service"}))
  end
end

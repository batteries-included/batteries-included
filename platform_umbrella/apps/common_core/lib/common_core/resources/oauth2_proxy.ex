defmodule CommonCore.Resources.Oauth2Proxy do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "oauth2_proxy"

  import CommonCore.Resources.ProxyUtils
  import CommonCore.StateSummary.Namespaces
  import CommonCore.StateSummary.URLs

  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.Secret

  @serve_port 80
  @web_port 4180
  @metrics_port 44_180
  @user_group_id 2000
  @component "oauth2-proxy"

  defp name(%SystemBattery{} = battery), do: name(battery.type)

  defp name(battery) when is_atom(battery), do: name(Atom.to_string(battery))

  defp name(battery) do
    sanitize("#{@component}-#{battery}")
  end

  resource(:deployment, battery, state) do
    name = name(battery)
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("revisionHistoryLimit", 10)
      |> Map.put(
        "selector",
        %{
          "matchLabels" => %{
            "battery/app" => name,
            "battery/component" => @component
          }
        }
      )
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => name,
              "battery/component" => @component,
              "battery/managed" => "true"
            }
          },
          "spec" => %{
            "automountServiceAccountToken" => true,
            "containers" => [
              %{
                "args" => [
                  "--http-address=0.0.0.0:#{@web_port}",
                  "--metrics-address=0.0.0.0:#{@metrics_port}",
                  "--email-domain=*",
                  "--upstream=static://200",
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
                  "--standard-logging=true"
                ],
                "env" => build_env(battery, state),
                "image" => CommonCore.Defaults.Images.oauth2_proxy_image(),
                "imagePullPolicy" => "IfNotPresent",
                "livenessProbe" => %{
                  "httpGet" => %{"path" => "/ping", "port" => "http", "scheme" => "HTTP"},
                  "initialDelaySeconds" => 0,
                  "timeoutSeconds" => 1
                },
                "name" => @component,
                "ports" => [
                  %{"containerPort" => @web_port, "name" => "http", "protocol" => "TCP"},
                  %{"containerPort" => @metrics_port, "name" => "metrics", "protocol" => "TCP"}
                ],
                "readinessProbe" => %{
                  "httpGet" => %{"path" => "/ready", "port" => "http", "scheme" => "HTTP"},
                  "initialDelaySeconds" => 0,
                  "periodSeconds" => 10,
                  "successThreshold" => 1,
                  "timeoutSeconds" => 5
                },
                "resources" => %{},
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false,
                  "capabilities" => %{"drop" => ["ALL"]},
                  "readOnlyRootFilesystem" => true,
                  "runAsGroup" => @user_group_id,
                  "runAsNonRoot" => true,
                  "runAsUser" => @user_group_id,
                  "seccompProfile" => %{"type" => "RuntimeDefault"}
                }
              }
            ],
            "serviceAccountName" => name,
            "tolerations" => []
          }
        }
      )

    :deployment
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.app_labels(name)
    |> B.component_label(@component)
    |> B.spec(spec)
    |> F.require_battery(state, :sso)
  end

  defp build_env(battery, state) do
    name = name(battery)
    redirect_url = state |> uri_for_battery(battery.type) |> URI.to_string()

    case CommonCore.StateSummary.KeycloakSummary.client(state.keycloak_state, Atom.to_string(battery.type)) do
      %{realm: realm, client: %{}} ->
        keycloak_url = state |> keycloak_uri_for_realm(realm) |> URI.to_string()

        [
          %{"name" => to_env_var("oidc-issuer-url"), "value" => keycloak_url},
          %{"name" => to_env_var("redirect-url"), "value" => redirect_url},
          %{
            "name" => to_env_var("client-id"),
            "valueFrom" => B.secret_key_ref(name, "client-id")
          },
          %{
            "name" => to_env_var("client-secret"),
            "valueFrom" => B.secret_key_ref(name, "client-secret")
          },
          %{
            "name" => to_env_var("cookie-secret"),
            "valueFrom" => B.secret_key_ref(name, "cookie-secret")
          }
        ]

      nil ->
        []
    end
  end

  defp to_env_var(s) do
    "OAUTH2_PROXY_#{s}"
    |> String.upcase()
    |> String.replace(" ", "_")
    |> String.replace("-", "_")
  end

  # TODO(jdt): this flaps on startup. fix it.
  resource(:secret, battery, state) do
    name = name(battery)
    namespace = core_namespace(state)

    data =
      case CommonCore.StateSummary.KeycloakSummary.client(state.keycloak_state, Atom.to_string(battery.type)) do
        %{realm: _realm, client: %{clientId: client_id, secret: client_secret}} ->
          %{}
          |> Map.put("client-id", client_id)
          |> Map.put("client-secret", client_secret)
          |> Map.put("cookie-secret", cookie_secret(battery, state))
          |> Secret.encode()

        nil ->
          %{}
      end

    :secret
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.app_labels(name)
    |> B.component_label(@component)
    |> B.data(data)
    |> F.require_battery(state, :sso)
  end

  resource(:service_account, battery, state) do
    name = name(battery)
    namespace = core_namespace(state)

    :service_account
    |> B.build_resource()
    |> Map.put("automountServiceAccountToken", true)
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.app_labels(name)
    |> B.component_label(@component)
    |> F.require_battery(state, :sso)
  end

  resource(:service, battery, state) do
    name = name(battery)
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{
          "appProtocol" => "http",
          "name" => "http",
          "port" => @serve_port,
          "protocol" => "TCP",
          "targetPort" => "http"
        },
        %{
          "appProtocol" => "http",
          "name" => "metrics",
          "port" => @metrics_port,
          "protocol" => "TCP",
          "targetPort" => "metrics"
        }
      ])
      |> Map.put(
        "selector",
        %{"battery/app" => name, "battery/component" => @component}
      )

    :service
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.app_labels(name)
    |> B.component_label(@component)
    |> B.spec(spec)
    |> F.require_battery(state, :sso)
  end
end

defmodule CommonCore.Resources.Oauth2Proxy do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "oauth2_proxy"

  import CommonCore.Resources.ProxyUtils
  import CommonCore.StateSummary.Namespaces
  import CommonCore.StateSummary.URLs

  alias CommonCore.Knative.Service, as: KnativeService
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.Secret

  @default_port 80
  @web_port 4180
  @metrics_port 44_180
  @user_group_id 2000

  @component "oauth2-proxy"

  resource(:deployment, battery, state) do
    if battery.type == :knative, do: nil

    case CommonCore.StateSummary.KeycloakSummary.client(state.keycloak_state, Atom.to_string(battery.type)) do
      %{realm: realm, client: %{}} ->
        %{
          name: service_name(battery),
          namespace: core_namespace(state),
          owner: battery.id,
          keycloak_url: state |> keycloak_uri_for_realm(realm) |> URI.to_string(),
          redirect_url: state |> uri_for_battery(battery.type) |> URI.to_string()
        }
        |> build_deployment()
        |> F.require_battery(state, :sso)

      nil ->
        nil
    end
  end

  resource(:secret, battery, state) do
    if battery.type == :knative, do: nil

    case CommonCore.StateSummary.KeycloakSummary.client(state.keycloak_state, Atom.to_string(battery.type)) do
      %{realm: _realm, client: %{clientId: client_id, secret: client_secret}} ->
        %{
          name: service_name(battery),
          namespace: core_namespace(state),
          client_id: client_id,
          client_secret: client_secret,
          cookie_secret: cookie_secret(battery)
        }
        |> build_secret()
        |> F.require_battery(state, :sso)

      nil ->
        nil
    end
  end

  resource(:service_account, battery, state) do
    if battery.type == :knative, do: nil

    %{
      name: service_name(battery),
      namespace: core_namespace(state)
    }
    |> build_service_account()
    |> F.require_battery(state, :sso)
  end

  resource(:service, battery, state) do
    if battery.type == :knative, do: nil

    %{
      name: service_name(battery),
      namespace: core_namespace(state)
    }
    |> build_service()
    |> F.require_battery(state, :sso)
  end

  multi_resource(:knative_deployments, battery, state) do
    if battery.type != :knative, do: nil

    state.knative_services
    |> Enum.filter(&KnativeService.sso_configured_properly?/1)
    |> Enum.map(fn %{id: id, name: name} = service ->
      case CommonCore.StateSummary.KeycloakSummary.client(state.keycloak_state, name) do
        %{realm: realm, client: %{}} ->
          deploy =
            %{
              name: service_name(name),
              namespace: battery.config.namespace,
              owner: id,
              keycloak_url: state |> keycloak_uri_for_realm(realm) |> URI.to_string(),
              redirect_url: state |> knative_url(service) |> URI.to_string()
            }
            |> build_deployment()
            |> F.require_battery(state, :sso)

          {"/proxy_deployment/#{id}", deploy}

        nil ->
          nil
      end
    end)
    # remove nil e.g. client doesn't exist yet
    |> Enum.filter(& &1)
    |> Map.new()
  end

  multi_resource(:knative_secrets, battery, state) do
    if battery.type != :knative, do: nil

    state.knative_services
    |> Enum.filter(&KnativeService.sso_configured_properly?/1)
    |> Enum.map(fn %{id: id, name: name} = _service ->
      case CommonCore.StateSummary.KeycloakSummary.client(state.keycloak_state, name) do
        %{realm: _realm, client: %{clientId: client_id, secret: client_secret}} ->
          secret =
            %{
              name: service_name(name),
              namespace: battery.config.namespace,
              client_id: client_id,
              client_secret: client_secret,
              cookie_secret: cookie_secret(battery)
            }
            |> build_secret()
            |> F.require_battery(state, :sso)

          {"/proxy_secret/#{id}", secret}

        nil ->
          nil
      end
    end)
    # remove nil e.g. client doesn't exist yet
    |> Enum.filter(& &1)
    |> Map.new()
  end

  multi_resource(:knative_service_accounts, battery, state) do
    if battery.type != :knative, do: nil

    state.knative_services
    |> Enum.filter(&KnativeService.sso_configured_properly?/1)
    |> Map.new(fn %{id: id, name: name} = _service ->
      sa =
        %{
          name: service_name(name),
          namespace: battery.config.namespace
        }
        |> build_service_account()
        |> F.require_battery(state, :sso)

      {"/proxy_sa/#{id}", sa}
    end)
  end

  multi_resource(:knative_services, battery, state) do
    if battery.type != :knative, do: nil

    state.knative_services
    |> Enum.filter(&KnativeService.sso_configured_properly?/1)
    |> Map.new(fn %{id: id, name: name} = _service ->
      svc =
        %{
          name: service_name(name),
          namespace: battery.config.namespace
        }
        |> build_service()
        |> F.require_battery(state, :sso)

      {"/proxy_service/#{id}", svc}
    end)
  end

  @spec build_deployment(%{
          name: String.t(),
          namespace: String.t(),
          owner: String.t(),
          keycloak_url: String.t(),
          redirect_url: String.t()
        }) :: map()
  defp build_deployment(%{
         name: name,
         namespace: namespace,
         owner: owner,
         keycloak_url: keycloak_url,
         redirect_url: redirect_url
       }) do
    template =
      %{
        "metadata" => %{"labels" => %{"battery/managed" => "true"}},
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
              "env" => build_env(name, keycloak_url, redirect_url),
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
      |> B.app_labels(name)
      |> B.component_labels(@component)
      |> B.add_owner(owner)

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
      |> Map.put("template", template)

    :deployment
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.app_labels(name)
    |> B.component_labels(@component)
    |> B.spec(spec)
  end

  @spec build_secret(%{
          name: String.t(),
          namespace: String.t(),
          client_id: String.t(),
          client_secret: String.t(),
          cookie_secret: String.t()
        }) :: map()
  defp build_secret(%{
         name: name,
         namespace: namespace,
         client_id: client_id,
         client_secret: client_secret,
         cookie_secret: cookie_secret
       }) do
    data =
      %{}
      |> Map.put("client-id", client_id)
      |> Map.put("client-secret", client_secret)
      |> Map.put("cookie-secret", cookie_secret)
      |> Secret.encode()

    :secret
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.app_labels(name)
    |> B.component_labels(@component)
    |> B.data(data)
  end

  @spec build_service_account(%{name: String.t(), namespace: String.t()}) :: map()
  defp build_service_account(%{name: name, namespace: namespace}) do
    :service_account
    |> B.build_resource()
    |> Map.put("automountServiceAccountToken", true)
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.app_labels(name)
    |> B.component_labels(@component)
  end

  @spec build_service(%{name: String.t(), namespace: String.t()}) :: map()
  defp build_service(%{name: name, namespace: namespace}) do
    spec =
      %{}
      |> Map.put("ports", [
        %{
          "appProtocol" => "http",
          "name" => "http",
          "port" => @default_port,
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
    |> B.component_labels(@component)
    |> B.spec(spec)
  end

  @spec build_env(String.t(), String.t(), String.t()) :: list(map())
  defp build_env(secret_name, keycloak_url, redirect_url) do
    [
      %{"name" => to_env_var("oidc-issuer-url"), "value" => keycloak_url},
      %{"name" => to_env_var("redirect-url"), "value" => redirect_url},
      %{
        "name" => to_env_var("client-id"),
        "valueFrom" => B.secret_key_ref(secret_name, "client-id")
      },
      %{
        "name" => to_env_var("client-secret"),
        "valueFrom" => B.secret_key_ref(secret_name, "client-secret")
      },
      %{
        "name" => to_env_var("cookie-secret"),
        "valueFrom" => B.secret_key_ref(secret_name, "cookie-secret")
      }
    ]
  end

  defp to_env_var(s) do
    "OAUTH2_PROXY_#{s}"
    |> String.upcase()
    |> String.replace(" ", "_")
    |> String.replace("-", "_")
  end
end

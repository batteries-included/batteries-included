defmodule CommonCore.Resources.Oauth2Proxy do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "oauth2_proxy"

  import CommonCore.Resources.ProxyUtils
  import CommonCore.StateSummary.Namespaces
  import CommonCore.StateSummary.URLs

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.StateSummary.KeycloakSummary

  @serve_port 80
  @user_group_id 2000
  @component "oauth2-proxy"

  resource(:deployment, battery, state) do
    name = service_name(battery)
    namespace = core_namespace(state)

    image = deployment_image(state)

    template =
      %{
        "metadata" => %{"labels" => %{"battery/managed" => "true"}},
        "spec" => %{
          "automountServiceAccountToken" => true,
          "containers" => [
            %{
              "args" => deployment_args("static://200"),
              "env" => build_env(battery, state),
              "image" => image,
              "imagePullPolicy" => "IfNotPresent",
              "livenessProbe" => %{
                "httpGet" => %{"path" => "/ping", "port" => "http", "scheme" => "HTTP"},
                "initialDelaySeconds" => 0,
                "timeoutSeconds" => 1
              },
              "name" => @component,
              "ports" => [
                %{"containerPort" => web_port(), "name" => "http", "protocol" => "TCP"},
                %{"containerPort" => metrics_port(), "name" => "metrics", "protocol" => "TCP"}
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
      |> B.add_owner(battery)

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
    |> F.require_battery(state, :sso)
    |> F.require_non_nil(image)
  end

  defp build_env(battery, state) do
    case KeycloakSummary.client(state.keycloak_state, battery.type) do
      %{realm: realm, client: %{}} ->
        deployment_env(%{
          redirect_url: state |> uri_for_battery(battery.type) |> URI.to_string(),
          keycloak_url: state |> keycloak_uri_for_realm(realm) |> URI.to_string(),
          secret_name: service_name(battery)
        })

      nil ->
        []
    end
  end

  resource(:secret, battery, state) do
    name = service_name(battery)
    namespace = core_namespace(state)

    data =
      case KeycloakSummary.client(state.keycloak_state, battery.type) do
        %{realm: _realm, client: client} ->
          secret_data(client, cookie_secret(battery))

        nil ->
          %{}
      end

    :secret
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.app_labels(name)
    |> B.component_labels(@component)
    |> B.data(data)
    |> F.require_battery(state, :sso)
  end

  resource(:service_account, battery, state) do
    name = service_name(battery)
    namespace = core_namespace(state)

    :service_account
    |> B.build_resource()
    |> Map.put("automountServiceAccountToken", true)
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.app_labels(name)
    |> B.component_labels(@component)
    |> F.require_battery(state, :sso)
  end

  resource(:service, battery, state) do
    name = service_name(battery)
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
          "port" => metrics_port(),
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
    |> F.require_battery(state, :sso)
  end
end

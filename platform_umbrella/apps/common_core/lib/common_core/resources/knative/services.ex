defmodule CommonCore.Resources.KnativeServices do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "knative-serving"

  import CommonCore.Resources.ProxyUtils
  import CommonCore.StateSummary.URLs

  alias CommonCore.Containers.EnvValue
  alias CommonCore.Knative.Service
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.StateSummary.Batteries
  alias CommonCore.StateSummary.KeycloakSummary

  def serving_service(%Service{} = service, battery, state) do
    template =
      %{
        "metadata" => %{
          "labels" => %{
            "battery/managed" => "true"
          }
        },
        "spec" => %{}
      }
      |> B.app_labels(service.name)
      |> B.component_labels(@app_name)
      |> B.add_owner(service)
      |> add_all_containers(service, state)
      |> add_rollout_duration(service)
      |> add_cluster_local_labels(service)

    spec = %{"template" => template}

    :knative_service
    |> B.build_resource()
    |> B.name(service.name)
    |> B.namespace(battery.config.namespace)
    |> B.app_labels(service.name)
    |> B.component_labels(@app_name)
    |> B.add_owner(service)
    |> B.spec(spec)
    |> add_rollout_duration(service)
    |> add_cluster_local_labels(service)
  end

  defp add_cluster_local_labels(resource_template, %{kube_internal: true}),
    do: B.label(resource_template, "networking.knative.dev/visibility", "cluster-local")

  defp add_cluster_local_labels(resource_template, _), do: resource_template

  defp add_rollout_duration(resource_template, %{rollout_duration: nil}), do: resource_template

  defp add_rollout_duration(resource_template, %{rollout_duration: dur}) when is_binary(dur) and dur == "",
    do: resource_template

  defp add_rollout_duration(resource_template, %{rollout_duration: dur}),
    do: B.annotation(resource_template, "serving.knative.dev/rollout-duration", dur)

  defp add_all_containers(resource_template, service, state) do
    # add the proxy container if needed
    containers =
      if Service.sso_configured_properly?(service) && Batteries.sso_installed?(state) do
        image = deployment_image(state)

        proxy = %{
          "args" => deployment_args("http://127.0.0.1:8000"),
          "env" => build_env(state, service),
          "image" => image,
          "livenessProbe" => %{
            "httpGet" => %{"path" => "/ping", "port" => "http", "scheme" => "HTTP"},
            "initialDelaySeconds" => 0,
            "timeoutSeconds" => 1
          },
          "name" => "proxy",
          "ports" => [
            %{"containerPort" => web_port(), "protocol" => "TCP"}
          ],
          "readinessProbe" => %{
            "httpGet" => %{"path" => "/ready", "port" => "http", "scheme" => "HTTP"},
            "initialDelaySeconds" => 0,
            "periodSeconds" => 10,
            "successThreshold" => 1,
            "timeoutSeconds" => 5
          }
        }

        service.containers
        |> Enum.with_index(8000)
        |> Enum.map(fn {c, i} -> to_container(c, service.env_values, i) end)
        |> List.insert_at(-1, proxy)
      else
        Enum.map(service.containers, fn c -> to_container(c, service.env_values) end)
      end

    init_containers = Enum.map(service.init_containers, fn c -> to_container(c, service.env_values) end)

    resource_template
    |> add_containers("containers", containers)
    |> add_containers("initContainers", init_containers)
  end

  defp add_containers(resource_template, _name, [] = containers) when containers == [] or is_nil(containers),
    do: resource_template

  defp add_containers(resource_template, spec_field_name, [_ | _] = containers) do
    put_in(resource_template, [Access.key("spec", %{}), Access.key(spec_field_name, [])], containers)
  end

  defp build_env(state, service) do
    case KeycloakSummary.client(state.keycloak_state, service.name) do
      %{realm: realm, client: %{}} ->
        deployment_env(%{
          redirect_url: state |> knative_url(service) |> URI.to_string(),
          keycloak_url: state |> keycloak_uri_for_realm(realm) |> URI.to_string(),
          secret_name: service_name(service.name)
        })

      nil ->
        []
    end
  end

  defp to_container(container, base_env_values) do
    env =
      base_env_values
      |> Enum.concat(container.env_values)
      |> Enum.map(&EnvValue.to_k8s_value/1)

    container
    |> Map.from_struct()
    |> Map.drop(["env_values", :env_values, "mounts", :mounts, :path, "path"])
    |> Map.put(:env, env)
  end

  defp to_container(container, base_env_values, port) do
    container
    |> to_container(base_env_values)
    |> Map.update(:env, [], fn envs -> envs ++ [%{"name" => "PORT", "value" => "#{port}"}] end)
  end

  multi_resource(:knative_services, battery, state) do
    Map.new(state.knative_services, fn s -> {"/service/#{s.id}", serving_service(s, battery, state)} end)
  end

  multi_resource(:knative_oauth2_proxy_secrets, battery, state) do
    Map.new(state.knative_services, fn s -> {"/proxy_secret/#{s.id}", proxy_secret(s, battery, state)} end)
  end

  defp proxy_secret(svc, battery, state) do
    name = service_name(svc)

    data =
      case KeycloakSummary.client(state.keycloak_state, svc.name) do
        %{realm: _realm, client: client} ->
          secret_data(client, cookie_secret(battery))

        nil ->
          %{}
      end

    :secret
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(battery.config.namespace)
    |> B.app_labels(svc.name)
    |> B.component_labels(@app_name)
    |> B.add_owner(svc)
    |> B.data(data)
    |> F.require_battery(state, :sso)
    |> F.require(Service.sso_configured_properly?(svc))
  end
end

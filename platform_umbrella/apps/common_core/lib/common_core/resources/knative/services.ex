defmodule CommonCore.Resources.KnativeServices do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "knative-serving"

  alias CommonCore.Containers.EnvValue
  alias CommonCore.Knative.Service
  alias CommonCore.Resources.Builder, as: B

  def serving_service(%Service{} = service, battery, _state) do
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
      |> add_containers("containers", service.containers, service.env_values)
      |> add_containers("initContainers", service.init_containers, service.env_values)
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

  defp add_cluster_local_labels(resource_template, %{oauth2_proxy: true}),
    do: B.label(resource_template, "networking.knative.dev/visibility", "cluster-local")

  defp add_cluster_local_labels(resource_template, %{kube_internal: true}),
    do: B.label(resource_template, "networking.knative.dev/visibility", "cluster-local")

  defp add_cluster_local_labels(resource_template, _), do: resource_template

  defp add_rollout_duration(resource_template, %{rollout_duration: nil}), do: resource_template

  defp add_rollout_duration(resource_template, %{rollout_duration: dur}) when is_binary(dur) and dur == "",
    do: resource_template

  defp add_rollout_duration(resource_template, %{rollout_duration: dur}),
    do: B.annotation(resource_template, "serving.knative.dev/rollout-duration", dur)

  defp add_containers(resource_template, _name, nil, _), do: resource_template

  defp add_containers(resource_template, _name, [] = containers, _) when containers == [], do: resource_template

  defp add_containers(resource_template, spec_field_name, [_ | _] = containers, base_env_values) do
    put_in(
      resource_template,
      [Access.key("spec", %{}), Access.key(spec_field_name, [])],
      Enum.map(containers, fn c -> to_container(c, base_env_values) end)
    )
  end

  defp to_container(container, base_env_values) do
    env =
      base_env_values
      |> Enum.concat(container.env_values)
      |> Enum.map(&EnvValue.to_k8s_value/1)

    container
    |> Map.from_struct()
    |> Map.drop(["env_values", :env_values, "mounts", :mounts, :path, "path"])
    |> Map.put("env", env)
  end

  multi_resource(:knative_services, battery, state) do
    Map.new(state.knative_services, fn s -> {"/service/#{s.id}", serving_service(s, battery, state)} end)
  end
end

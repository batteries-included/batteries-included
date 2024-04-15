defmodule ControlServerWeb.KNativeServiceJSON do
  alias CommonCore.Containers.Container
  alias CommonCore.Containers.EnvValue
  alias CommonCore.Knative.Service

  @doc """
  Renders a list of services.
  """
  def index(%{services: services}) do
    %{data: for(service <- services, do: data(service))}
  end

  @doc """
  Renders a single service.
  """
  def show(%{service: service}) do
    %{data: data(service)}
  end

  defp data(%Service{} = service) do
    %{
      id: service.id,
      name: service.name,
      rollout_duration: service.rollout_duration,
      oauth2_proxy: service.oauth2_proxy,
      kube_internal: service.kube_internal,
      containers: for(container <- service.containers || [], do: data(container)),
      env_values: for(env_value <- service.env_values || [], do: data(env_value))
    }
  end

  defp data(%Container{} = container) do
    %{
      name: container.name,
      image: container.image,
      command: container.command,
      args: container.args,
      env_values: for(env_value <- container.env_values || [], do: data(env_value))
    }
  end

  defp data(%EnvValue{} = env_value) do
    %{
      name: env_value.name,
      source_type: env_value.source_type,
      value: env_value.value,
      source_name: env_value.source_name,
      source_key: env_value.source_key,
      source_optional: env_value.source_optional
    }
  end

  defp data(nil), do: nil
end

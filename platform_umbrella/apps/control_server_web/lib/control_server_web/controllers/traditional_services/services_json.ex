defmodule ControlServerWeb.TraditionalServicesJSON do
  alias CommonCore.Containers.Container
  alias CommonCore.Containers.EnvValue
  alias CommonCore.TraditionalServices.Service

  @doc """
  Renders a list of traditional_services.
  """
  def index(%{traditional_services: traditional_services}) do
    %{data: for(service <- traditional_services, do: data(service))}
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
      containers: for(container <- service.containers || [], do: data(container)),
      init_containers: for(container <- service.init_containers || [], do: data(container)),
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
end

defmodule CommonCore.Resources.TraditionalServices do
  @moduledoc false

  use CommonCore.Resources.ResourceGenerator, app_name: "traditional-services"

  import CommonCore.Resources.MapUtils

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.TraditionalServices.Service

  resource(:namespace, battery, _state) do
    :namespace
    |> B.build_resource()
    |> B.name(battery.config.namespace)
    |> B.app_labels(@app_name)
  end

  multi_resource(:kube_deployment, battery, state) do
    Enum.map(state.traditional_services, fn service ->
      case service.kube_deployment_type do
        :statefulset -> stateful_set(service, battery, state)
        :deployment -> deployment(service, battery, state)
      end
    end)
  end

  multi_resource(:service_account, battery, state) do
    Enum.map(state.traditional_services, fn service -> service_account(service, battery, state) end)
  end

  defp service_account(%Service{} = service, battery, _state) do
    :service_account
    |> B.build_resource()
    |> B.name(service_account_name(service))
    |> B.namespace(battery.config.namespace)
  end

  defp deployment(service, battery, state) do
    template = template(service, battery, state)

    spec =
      %{}
      |> Map.put("selector", %{
        "matchLabels" => %{"battery/app" => service.name, "battery/component" => @app_name}
      })
      |> Map.put("replicas", service.num_instances)
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name(service.name)
    |> B.namespace(battery.config.namespace)
    |> B.app_labels(service.name)
    |> B.component_labels(@app_name)
    |> B.spec(spec)
  end

  defp stateful_set(service, battery, state) do
    template = template(service, battery, state)

    spec =
      %{}
      |> Map.put("selector", %{
        "matchLabels" => %{"battery/app" => service.name, "battery/component" => @app_name}
      })
      |> Map.put("replicas", service.num_instances)
      |> B.template(template)

    :stateful_set
    |> B.build_resource()
    |> B.name(service.name)
    |> B.namespace(battery.config.namespace)
    |> B.app_labels(service.name)
    |> B.component_labels(@app_name)
    |> B.spec(spec)
  end

  defp template(service, battery, state) do
    %{
      "metadata" => %{
        "labels" => %{"battery/managed" => "true"}
      },
      "spec" => %{
        "initContainers" => init_containers(service, battery, state),
        "containers" => containers(service, battery, state),
        "serviceAccountName" => service_account_name(service)
      }
    }
    |> B.app_labels(service.name)
    |> B.component_labels(@app_name)
    |> B.add_owner(service)
  end

  defp init_containers(service, _battery, _state) do
    Enum.map(service.init_containers, fn container ->
      %{
        "name" => container.name,
        "image" => container.image,
        "resources" => resources(service)
      }
    end)
  end

  defp containers(service, _battery, _state) do
    Enum.map(service.containers, fn container ->
      %{
        "name" => container.name,
        "image" => container.image,
        "resources" => resources(service)
      }
    end)
  end

  defp resources(%Service{} = service) do
    limits =
      %{}
      |> maybe_put("cpu", format_cpu_resource(service.cpu_limits))
      |> maybe_put("memory", format_resource(service.memory_limits))

    requests =
      %{}
      |> maybe_put("cpu", format_cpu_resource(service.cpu_requested))
      |> maybe_put("memory", format_resource(service.memory_requested))

    %{} |> maybe_put("limits", limits) |> maybe_put("requests", requests)
  end

  defp service_account_name(%Service{} = service) do
    "#{service.name}-service-account"
  end

  defp format_resource(nil), do: nil
  defp format_resource(value), do: to_string(value)

  defp format_cpu_resource(nil), do: nil

  defp format_cpu_resource(value) do
    "#{value}m"
  end
end

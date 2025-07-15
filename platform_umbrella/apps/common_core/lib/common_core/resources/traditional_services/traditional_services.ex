defmodule CommonCore.Resources.TraditionalServices do
  @moduledoc false

  use CommonCore.Resources.ResourceGenerator, app_name: "traditional-services"

  import CommonCore.StateSummary.Hosts
  import CommonCore.Util.Map

  alias CommonCore.Containers.EnvValue
  alias CommonCore.OpenAPI.IstioVirtualService.VirtualService
  alias CommonCore.Port
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.VirtualServiceBuilder, as: V
  alias CommonCore.TraditionalServices.Service

  resource(:namespace, battery, _state) do
    :namespace
    |> B.build_resource()
    |> B.name(battery.config.namespace)
    |> B.app_labels(@app_name)
    |> B.label("istio-injection", "enabled")
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

  multi_resource(:service, battery, state) do
    Enum.map(state.traditional_services, fn service -> service(service, battery, state) end)
  end

  multi_resource(:virtual_service, battery, state) do
    Enum.map(state.traditional_services, fn service -> virtual_service(service, battery, state) end)
  end

  defp virtual_service(%{kube_internal: true}, _battery, _state), do: nil
  defp virtual_service(%{ports: []}, _battery, _state), do: nil

  defp virtual_service(service, battery, state) do
    ssl_enabled? = CommonCore.StateSummary.SSL.ssl_enabled?(state)
    ports = to_svc_ports(service)

    # TODO: allow specifying 'default' port instead of just using the first port?
    [default_port | _] = ports

    spec =
      [hosts: traditional_hosts(state, service)]
      |> VirtualService.new!()
      |> V.fallback(service.name, default_port.port)
      |> V.maybe_https_redirect(ssl_enabled?)

    :istio_virtual_service
    |> B.build_resource()
    |> B.namespace(battery.config.namespace)
    |> B.name(service.name)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
    |> F.require_non_empty(ports)
  end

  defp service(service, battery, _state) do
    ports = to_svc_ports(service)

    spec =
      %{}
      |> Map.put("ports", ports)
      |> Map.put("selector", %{"battery/app" => service.name, "battery/component" => @app_name})
      |> Map.put("type", "ClusterIP")

    :service
    |> B.build_resource()
    |> B.name(service.name)
    |> B.namespace(battery.config.namespace)
    |> B.spec(spec)
    |> F.require_non_empty(ports)
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
    |> B.add_owner(service)
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
    |> B.add_owner(service)
    |> B.spec(spec)
  end

  defp template(service, battery, state) do
    %{
      "metadata" => %{
        "labels" => %{"battery/managed" => "true"}
      },
      "spec" => %{
        "initContainers" => containers(service.init_containers, service, battery, state),
        "containers" => containers(service.containers, service, battery, state),
        "serviceAccountName" => service_account_name(service),
        "volumes" => volumes(service, battery, state)
      }
    }
    |> B.app_labels(service.name)
    |> B.component_labels(@app_name)
    |> B.add_owner(service)
  end

  defp containers(containers, service, _battery, _state) do
    Enum.map(containers, fn container ->
      %{
        "name" => container.name,
        "image" => container.image,
        "resources" => resources(service),
        "volumeMounts" => volume_mounts(container, service.mounts),
        "env" => env(service, container),
        "command" => container.command,
        "args" => container.args
      }
    end)
  end

  defp volumes(service, _battery, _state) do
    Enum.map(service.volumes, &CommonCore.TraditionalServices.Volume.to_k8s_volume/1)
  end

  defp volume_mounts(container, service_mounts) do
    Enum.map(container.mounts ++ service_mounts, fn mount ->
      %{"mountPath" => mount.mount_path, "name" => mount.volume_name, "readOnly" => mount.read_only}
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

  defp env(service, container) do
    service.env_values
    |> Enum.concat(container.env_values)
    |> Enum.map(&EnvValue.to_k8s_value/1)
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

  defp to_svc_ports(%{ports: ports} = _service), do: Enum.map(ports, &to_svc_port/1)
  defp to_svc_ports(_), do: []

  defp to_svc_port(port), do: %{name: port.name, port: port.number, protocol: Port.k8s_protocol(port)}
end

defmodule CommonCore.Resources.TraditionalServices do
  @moduledoc false

  use CommonCore.Resources.ResourceGenerator, app_name: "traditional-services"

  import CommonCore.StateSummary.Hosts
  import CommonCore.Util.Map

  alias CommonCore.Containers.EnvValue
  alias CommonCore.Port
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.RouteBuilder, as: R
  alias CommonCore.TraditionalServices.Service

  resource(:namespace, battery, _state) do
    :namespace
    |> B.build_resource()
    |> B.name(battery.config.namespace)
    |> B.app_labels(@app_name)
    |> B.label("istio-injection", "disabled")
    |> B.label("istio.io/dataplane-mode", "ambient")
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

  multi_resource(:http_route, battery, state) do
    Enum.map(state.traditional_services, fn service -> route(service, battery, state) end)
  end

  defp route(%{kube_internal: true}, _battery, _state), do: nil
  defp route(%{ports: []}, _battery, _state), do: nil

  defp route(service, battery, state) do
    namespace = battery.config.namespace

    # TODO: allow specifying 'default' port instead of just using the first port?
    [default_port | _] = service.ports

    # TODO: fix!!
    # ssl_enabled? = CommonCore.StateSummary.SSL.ssl_enabled?(state)

    spec =
      state
      |> traditional_hosts(service)
      |> R.new_httproute_spec_for_hosts(state)
      |> R.add_backend(service.name, default_port.number)

    :gateway_http_route
    |> B.build_resource()
    |> B.name(service.name)
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
    |> F.require_non_empty(service.ports)
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

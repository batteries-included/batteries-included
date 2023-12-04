defmodule CommonCore.Resources.KnativeServing do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "knative-serving"

  import CommonCore.StateSummary.Hosts
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Knative.EnvValue
  alias CommonCore.Knative.Service
  alias CommonCore.Resources.Builder, as: B

  resource(:namespace_dest, battery, _state) do
    :namespace
    |> B.build_resource()
    |> B.name(battery.config.namespace)
    |> B.label("istio-injection", "enabled")
  end

  resource(:knative_serving, battery, state) do
    namespace = battery.config.namespace

    istio_namespace = istio_namespace(state)

    spec = %{
      "config" => %{
        "istio" => %{
          "gateway.#{namespace}.knative-ingress-gateway" => "istio-ingressgateway.#{istio_namespace}.svc.cluster.local",
          "local-gateway.#{namespace}.knative-local-gateway" =>
            "knative-local-gateway.#{istio_namespace}.svc.cluster.local"
        }
      },
      "ingress" => %{"istio" => %{"enabled" => true}}
    }

    :knative_serving
    |> B.build_resource()
    |> B.namespace(namespace)
    |> B.name("knative-serving")
    |> B.spec(spec)
  end

  resource(:domain_config, battery, state) do
    data = Map.put(%{}, knative_base_host(state), "")

    :config_map
    |> B.build_resource()
    |> B.name("config-domain")
    |> B.namespace(battery.config.namespace)
    |> Map.put("data", data)
  end

  resource(:features_config, battery, _state) do
    data =
      %{}
      |> Map.put("multi-container", "enabled")
      |> Map.put("kubernetes.podspec-volumes-emptydir", "enabled")
      |> Map.put("kubernetes.podspec-init-containers", "enabled")

    :config_map
    |> B.build_resource()
    |> B.name("config-features")
    |> B.namespace(battery.config.namespace)
    |> Map.put("data", data)
  end

  def serving_service(%Service{} = service, battery, _state) do
    template =
      %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => @app_name,
            "battery/managed" => "true"
          }
        },
        "spec" => %{}
      }
      |> add_containers("containers", service.containers, service.env_values)
      |> add_containers("initContainers", service.init_containers, service.env_values)
      |> add_rollout_duration(service)

    spec = %{"template" => template}

    :knative_service
    |> B.build_resource()
    |> B.name(service.name)
    |> B.namespace(battery.config.namespace)
    |> B.owner_label(service.id)
    |> B.spec(spec)
    |> add_rollout_duration(service)
  end

  defp add_rollout_duration(resource_template, %{rollout_duration: nil}), do: resource_template

  defp add_rollout_duration(resource_template, %{rollout_duration: dur}) when is_binary(dur) and dur == "",
    do: resource_template

  defp add_rollout_duration(resource_template, %{rollout_duration: dur}) do
    update_in(
      resource_template,
      [Access.key("metadata", %{}), Access.key("annotations", %{})],
      fn anns ->
        Map.put(anns || %{}, "serving.knative.dev/rollout-duration", dur)
      end
    )
  end

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
      |> Enum.map(&to_env_var/1)

    container
    |> Map.from_struct()
    |> Map.drop(["env_values", :env_values])
    |> Map.put("env", env)
  end

  defp to_env_var(%EnvValue{source_type: :value} = val) do
    %{"name" => val.name, "value" => val.value}
  end

  defp to_env_var(%EnvValue{source_type: :config} = val) do
    %{
      "name" => val.name,
      "valueFrom" => %{
        "configMapKeyRef" => %{
          "key" => val.source_key,
          "name" => val.source_name,
          "optional" => val.source_optional
        }
      }
    }
  end

  defp to_env_var(%EnvValue{source_type: :secret} = val) do
    %{
      "name" => val.name,
      "valueFrom" => %{
        "secretKeyRef" => %{
          "key" => val.source_key,
          "name" => val.source_name,
          "optional" => val.source_optional
        }
      }
    }
  end

  multi_resource(:knative_services, battery, state) do
    state.knative_services
    |> Enum.map(fn s ->
      {"/service/#{s.id}", serving_service(s, battery, state)}
    end)
    |> Map.new()
  end
end

defmodule CommonCore.Resources.Ollama do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "ollama"

  import CommonCore.Resources.GPU
  import CommonCore.StateSummary.Namespaces
  import CommonCore.Util.Map

  alias CommonCore.Resources.Builder, as: B

  resource(:service_account_ollama, _battery, state) do
    namespace = ai_namespace(state)

    :service_account
    |> B.build_resource()
    |> Map.put("automountServiceAccountToken", true)
    |> B.name("ollama")
    |> B.namespace(namespace)
  end

  multi_resource(:deployment, battery, state) do
    Enum.map(state.model_instances, fn model_instance -> deployment(model_instance, battery, state) end)
  end

  multi_resource(:services, battery, state) do
    Enum.map(state.model_instances, fn model_instance -> service(model_instance, battery, state) end)
  end

  def service(model_instance, _battery, state) do
    namespace = ai_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [%{"name" => "http", "port" => 11_434, "protocol" => "TCP", "targetPort" => "http"}])
      |> Map.put("selector", %{"battery/app" => @app_name, "battery/ollama" => model_instance.name})

    :service
    |> B.build_resource()
    |> B.name("ollama-#{model_instance.name}")
    |> B.spec(spec)
    |> B.namespace(namespace)
    |> B.add_owner(model_instance)
  end

  def deployment(model_instance, battery, state) do
    namespace = ai_namespace(state)

    spec = %{
      "containers" => [
        %{
          "image" => battery.config.image,
          "resources" => resources(model_instance),
          "env" => env(model_instance),
          "lifecycle" => lifecycle(model_instance),
          "livenessProbe" => %{
            "failureThreshold" => 10,
            "httpGet" => %{"path" => "/", "port" => "http"},
            "initialDelaySeconds" => 60,
            "periodSeconds" => 10,
            "successThreshold" => 1,
            "timeoutSeconds" => 5
          },
          "name" => "ollama",
          "ports" => [%{"containerPort" => 11_434, "name" => "http", "protocol" => "TCP"}],
          "readinessProbe" => %{
            "failureThreshold" => 10,
            "httpGet" => %{"path" => "/", "port" => "http"},
            "initialDelaySeconds" => 30,
            "periodSeconds" => 5,
            "successThreshold" => 1,
            "timeoutSeconds" => 3
          },
          "volumeMounts" => [%{"mountPath" => "/root/.ollama", "name" => "ollama-data"}]
        }
      ],
      "serviceAccountName" => "ollama",
      "volumes" => [%{"emptyDir" => %{}, "name" => "ollama-data"}]
    }

    template =
      %{}
      |> B.spec(spec)
      |> maybe_add_node_selector(model_instance)
      |> maybe_add_tolerations(model_instance)
      |> B.app_labels(@app_name)
      |> B.add_owner(model_instance)
      |> B.label("battery/ollama", model_instance.name)
      |> B.label("battery/managed", "true")

    spec =
      %{}
      |> Map.put("replicas", model_instance.num_instances)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/ollama" => model_instance.name}}
      )
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("ollama-#{model_instance.name}")
    |> B.spec(spec)
    |> B.namespace(namespace)
    |> B.add_owner(model_instance)
  end

  defp resources(%{} = model_instance) do
    limits =
      %{}
      |> maybe_put("cpu", format_cpu_resource(model_instance.cpu_limits))
      |> maybe_put("memory", format_resource(model_instance.memory_limits))
      |> maybe_put("nvidia.com/gpu", format_resource(model_instance.gpu_count))

    requests =
      %{}
      |> maybe_put("cpu", format_cpu_resource(model_instance.cpu_requested))
      |> maybe_put("memory", format_resource(model_instance.memory_requested))

    %{}
    |> maybe_put("limits", limits)
    |> maybe_put("requests", requests)
  end

  defp env(%{gpu_count: gpu_count}) when not is_nil(gpu_count) and gpu_count > 0 do
    [
      %{
        "name" => "PATH",
        "value" =>
          "/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
      },
      %{"name" => "LD_LIBRARY_PATH", "value" => "/usr/local/nvidia/lib:/usr/local/nvidia/lib64"},
      %{"name" => "NVIDIA_DRIVER_CAPABILITIES", "value" => "compute,utility"},
      %{"name" => "NVIDIA_VISIBLE_DEVICES", "value" => "all"}
    ]
  end

  defp env(_model_instance), do: []

  defp lifecycle(%{model: model}),
    do: %{"postStart" => %{"exec" => %{"command" => ["/bin/sh", "-c", "echo '#{model}' | xargs -n1 /bin/ollama pull "]}}}

  defp format_resource(nil), do: nil
  defp format_resource(value), do: to_string(value)

  defp format_cpu_resource(nil), do: nil

  defp format_cpu_resource(value) do
    "#{value}m"
  end
end

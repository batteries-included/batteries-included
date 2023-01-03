defmodule KubeResources.KnativeServing do
  import CommonCore.SystemState.Namespaces
  import CommonCore.SystemState.Hosts

  alias KubeExt.Builder, as: B
  alias KubeExt.KubeState.Hosts
  alias CommonCore.Defaults

  @app_name "knative-serving"

  def namespace_dest(battery, _state) do
    B.build_resource(:namespace)
    |> B.name(battery.config.namespace)
    |> B.app_labels(@app_name)
    |> B.label("istio-injection", "enabled")
  end

  def knative_serving(battery, state) do
    namespace = battery.config.namespace

    istio_namespace = istio_namespace(state)

    spec = %{
      "config" => %{
        "istio" => %{
          "gateway.#{namespace}.knative-ingress-gateway" =>
            "ingressgateway.#{istio_namespace}.svc.cluster.local",
          "local-gateway.#{namespace}.knative-local-gateway" =>
            "knative-local-gateway.#{istio_namespace}.svc.cluster.local"
        }
      },
      "ingress" => %{"istio" => %{"enabled" => true}}
    }

    B.build_resource(:knative_serving)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("knative-serving")
    |> B.spec(spec)
  end

  def domain_config(battery, state) do
    data = Map.put(%{}, knative_host(state), "")

    B.build_resource(:config_map)
    |> B.name("config-domain")
    |> B.namespace(battery.config.namespace)
    |> B.app_labels(@app_name)
    |> Map.put("data", data)
  end

  def serving_service(%{} = service, battery, _state) do
    spec = %{
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/owner" => service.id,
            "battery/app" => @app_name,
            "battery/managed" => "true"
          }
        },
        "spec" => %{
          "containers" => [
            %{
              "image" => service.image,
              "env" => [%{"name" => "TARGET", "value" => "Batteries Included"}]
            }
          ]
        }
      }
    }

    B.build_resource(:knative_service)
    |> B.name(service.name)
    |> B.namespace(battery.config.namespace)
    |> B.owner_label(service.id)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  def url(%{} = service) do
    # assume the default config for now /shrug
    "http://#{service.name}.#{Defaults.Namespaces.knative()}.#{Hosts.knative()}"
  end

  def url(%{} = service, state) do
    # assume the default config for now /shrug
    "http://#{service.name}.#{Defaults.Namespaces.knative()}.#{knative_host(state)}"
  end

  @spec materialize(map(), map()) :: map()
  def materialize(battery, state) do
    res =
      state.knative_services
      |> Enum.map(fn s ->
        {"/service/#{s.id}", serving_service(s, battery, state)}
      end)
      |> Map.new()
      |> Map.merge(%{
        "/namespace" => namespace_dest(battery, state),
        "/knative_serving" => knative_serving(battery, state),
        "/domain_config" => domain_config(battery, state)
      })

    res
  end
end

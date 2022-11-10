defmodule KubeResources.KnativeServing do
  alias KubeExt.Builder, as: B
  alias KubeExt.KubeState.Hosts
  alias KubeResources.DevtoolsSettings

  @app_name "knative-serving"

  def namespace_dest(battery, _state) do
    knative_dest_namespace = DevtoolsSettings.knative_namespace(battery.config)

    B.build_resource(:namespace)
    |> B.name(knative_dest_namespace)
    |> B.app_labels(@app_name)
    |> B.label("istio-injection", "enabled")
  end

  def knative_serving(battery, _state) do
    knative_dest_namespace = DevtoolsSettings.knative_namespace(battery.config)

    spec = %{
      "config" => %{
        "istio" => %{
          "gateway.battery-knative.knative-ingress-gateway" =>
            "ingressgateway.battery-istio.svc.cluster.local",
          "local-gateway.battery-knative.knative-local-gateway" =>
            "knative-local-gateway.battery-istio.svc.cluster.local"
        }
      },
      "ingress" => %{"istio" => %{"enabled" => true}}
    }

    B.build_resource(:knative_serving)
    |> B.namespace(knative_dest_namespace)
    |> B.app_labels(@app_name)
    |> B.name("knative-serving")
    |> B.spec(spec)
  end

  def domain_config(battery, _state) do
    namespace = DevtoolsSettings.knative_namespace(battery.config)

    data = Map.put(%{}, Hosts.knative(), "")

    B.build_resource(:config_map)
    |> B.name("config-domain")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> Map.put("data", data)
  end

  def serving_service(%{} = service, battery, _state) do
    namespace = DevtoolsSettings.knative_namespace(battery.config)

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
    |> B.namespace(namespace)
    |> B.owner_label(service.id)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  def url(%{} = service) do
    # assume the default config for now /shrug
    namespace = DevtoolsSettings.knative_namespace(%{})
    "http://#{service.name}.#{namespace}.#{Hosts.knative()}"
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

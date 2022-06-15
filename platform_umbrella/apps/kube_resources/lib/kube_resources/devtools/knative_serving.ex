defmodule KubeResources.KnativeServing do
  alias ControlServer.Knative
  alias KubeExt.Builder, as: B
  alias KubeExt.KubeState.Hosts
  alias KubeResources.DevtoolsSettings

  @app_name "knative-serving"

  def namespace_dest(config) do
    knative_dest_namespace = DevtoolsSettings.knative_destination_namespace(config)

    B.build_resource(:namespace)
    |> B.name(knative_dest_namespace)
    |> B.app_labels(@app_name)
    |> B.label("istio-injection", "enabled")
  end

  def knative_serving(config) do
    knative_dest_namespace = DevtoolsSettings.knative_destination_namespace(config)

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

  def domain_config(config) do
    namespace = DevtoolsSettings.knative_destination_namespace(config)

    data = Map.put(%{}, Hosts.knative(), "")

    B.build_resource(:config_map)
    |> B.name("config-domain")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> Map.put("data", data)
  end

  def serving_service(%Knative.Service{} = service, config) do
    namespace = DevtoolsSettings.knative_destination_namespace(config)

    spec = %{
      "template" => %{
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
    |> B.spec(spec)
    |> B.owner_label(service.id)
  end

  def url(%Knative.Service{} = service) do
    # assume the default config for now /shrug
    namespace = DevtoolsSettings.knative_destination_namespace(%{})
    "//#{service.name}.#{namespace}.#{Hosts.knative()}"
  end

  @spec materialize(map()) :: map()
  def materialize(config) do
    Knative.list_services()
    |> Enum.map(fn s ->
      {"/service/#{s.id}", serving_service(s, config)}
    end)
    |> Enum.into(%{
      "/namespace" => namespace_dest(config),
      "/knative_serving" => knative_serving(config),
      "/domain_config" => domain_config(config)
    })
  end
end

defmodule KubeResources.KnativeServices do
  alias ControlServer.Knative
  alias KubeExt.Builder, as: B
  alias KubeExt.KubeState.Hosts
  alias KubeResources.DevtoolsSettings

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
    |> Enum.into(%{})
  end
end

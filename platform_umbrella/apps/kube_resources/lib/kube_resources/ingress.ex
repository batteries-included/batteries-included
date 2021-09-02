defmodule KubeResources.Ingress do
  alias ControlServer.Services
  alias ControlServer.Services.BaseService
  alias KubeResources.BatteryIngress
  alias KubeResources.BatterySettings
  alias KubeResources.MLIngress
  alias KubeResources.MonitoringIngress

  require Logger

  def battery_ingress(config) do
    ns = BatterySettings.namespace(config)
    computed_paths = paths()

    ingress(computed_paths, ns)
  end

  def paths do
    # TODO: Figure out a better way for this. Going back to the
    # DB even though we know that nothing has changed feels icky.
    base_services = Services.list_base_services()
    Enum.flat_map(base_services, &base_service_paths/1)
  end

  def base_service_paths(%BaseService{service_type: :monitoring, config: config} = _base_service) do
    MonitoringIngress.paths(config)
  end

  def base_service_paths(%BaseService{service_type: :battery, config: config} = _base_service) do
    BatteryIngress.paths(config)
  end

  def base_service_paths(%BaseService{service_type: :ml, config: config} = _base_service) do
    MLIngress.paths(config)
  end

  def base_service_paths(%BaseService{} = bs) do
    Logger.debug("#{inspect(bs)}")
    []
  end

  def ingress([] = _paths, _), do: []

  def ingress(paths, ns) do
    %{
      "apiVersion" => "networking.k8s.io/v1",
      "kind" => "Ingress",
      "metadata" => %{
        "name" => "main-ingress",
        "namespace" => ns,
        "annotations" => %{
          "kubernetes.io/ingress.class" => "kong",
          "konghq.com/strip-path" => "true"
        }
      },
      "spec" => %{
        "rules" => [%{"http" => %{"paths" => paths}}]
      }
    }
  end
end

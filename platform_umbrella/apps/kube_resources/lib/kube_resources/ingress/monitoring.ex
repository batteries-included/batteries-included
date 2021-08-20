defmodule KubeResources.MonitoringIngress do
  alias KubeResources.MonitoringSettings

  def paths(config) do
    name = MonitoringSettings.grafana_name(config)

    [
      %{
        "path" => "/x/grafana",
        "pathType" => "Prefix",
        "backend" => %{
          "service" => %{
            "name" => name,
            "port" => %{"number" => 3000}
          }
        }
      }
    ]
  end
end

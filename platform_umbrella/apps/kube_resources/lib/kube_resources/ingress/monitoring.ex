defmodule KubeResources.MonitoringIngress do
  def paths(_config) do
    [
      %{
        "path" => "/x/grafana",
        "pathType" => "Prefix",
        "backend" => %{
          "service" => %{
            "name" => "grafana",
            "port" => %{"number" => 3000}
          }
        }
      }
    ]
  end
end

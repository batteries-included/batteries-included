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
      },
      %{
        "path" => "/x/prometheus",
        "pathType" => "Prefix",
        "backend" => %{
          "service" => %{
            "name" => "prometheus-main",
            "port" => %{"name" => "web"}
          }
        }
      },
      %{
        "path" => "/x/alertmanager",
        "pathType" => "Prefix",
        "backend" => %{
          "service" => %{
            "name" => "alertmanager-main",
            "port" => %{"name" => "web"}
          }
        }
      }
    ]
  end
end

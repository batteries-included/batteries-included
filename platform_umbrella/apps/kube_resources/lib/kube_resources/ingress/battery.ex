defmodule KubeResources.BatteryIngress do
  def paths(_config) do
    [
      %{
        "path" => "/x/echo",
        "pathType" => "Prefix",
        "backend" => %{
          "service" => %{
            "name" => "echo",
            "port" => %{"number" => 80}
          }
        }
      }
    ]
  end
end

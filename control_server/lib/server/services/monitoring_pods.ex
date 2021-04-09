defmodule Server.Services.MonitoringPods do
  def get do
    {:ok, res} =
      K8s.Client.list("v1", :pods, namespace: "monitoring")
      |> K8s.Client.run(Bonny.Config.cluster_name())

    Map.get(res, "items", [])
  end
end

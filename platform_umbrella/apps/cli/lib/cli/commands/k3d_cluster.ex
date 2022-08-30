defmodule CLI.Commands.K3DCluster do
  require Logger

  def spec do
    [
      name: "cluster:k3d"
    ]
  end

  def run(_command, _parse_result) do
    Logger.debug("Starting K3d Cluster")
  end
end

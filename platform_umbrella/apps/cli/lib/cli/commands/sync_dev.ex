defmodule CLI.Commands.SyncDev do
  require Logger

  def spec do
    [
      name: "sync:dev"
    ]
  end

  def run(_command, _parse_result) do
    Logger.debug("Sync without control server")
    :ok = KubeRawResources.InitialSync.dev_sync()
  end
end

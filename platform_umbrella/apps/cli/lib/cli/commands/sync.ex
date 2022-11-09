defmodule CLI.Commands.Sync do
  require Logger

  def spec do
    [
      name: "sync"
    ]
  end

  def run(_command, _parse_result) do
    Logger.debug("Sync with everything")
    {:ok, _} = CLI.InitialSync.sync()
  end
end

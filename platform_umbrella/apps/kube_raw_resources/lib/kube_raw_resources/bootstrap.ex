defmodule KubeRawResources.Bootstrap do
  @moduledoc """
  Documentation for `Bootstrap`.
  """

  alias KubeRawResources.InitialSync

  require Logger

  @app :kube_raw_resources

  defp load_app do
    Logger.debug("Loading application #{@app}")

    with {:ok, _apps} <- Application.ensure_all_started(@app, :permanent) do
      :ok
    end
  end

  def sync do
    Logger.debug("Running")
    :ok = load_app()
    Logger.debug("Done starting application")
    InitialSync.sync(sync_method: :sync_dev)
  end
end

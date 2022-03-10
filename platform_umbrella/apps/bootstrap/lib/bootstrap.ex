defmodule Bootstrap do
  @moduledoc """
  Documentation for `Bootstrap`.
  """

  alias Bootstrap.InitialSync

  require Logger

  @app :bootstrap

  defp load_app do
    Logger.debug("Loading application #{@app}")
    Application.ensure_all_started(@app, :permanent)
  end

  def run do
    Logger.debug("Running")
    load_app()
    Logger.debug("Done starting application")
    InitialSync.sync()
  end
end

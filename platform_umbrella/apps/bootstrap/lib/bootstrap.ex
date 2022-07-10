defmodule Bootstrap do
  @moduledoc """
  Documentation for `Bootstrap`.
  """

  alias Bootstrap.InitialSync

  require Logger

  @app :bootstrap

  defp load_app do
    Logger.debug("Loading application #{@app}")

    with {:ok, _apps} <- Application.ensure_all_started(@app, :permanent) do
      :ok
    end
  end

  def dump do
    Logger.debug("Running")
    :ok = load_app()
    Logger.debug("Done starting application")

    outdir =
      case Enum.fetch(System.argv(), 0) do
        :error -> raise "Usage: Bootstrap.dump <output-dir>"
        {:ok, outdir} -> outdir
      end

    InitialSync.dump(outdir)
  end

  def run do
    Logger.debug("Running")
    :ok = load_app()
    Logger.debug("Done starting application")
    InitialSync.sync()
  end
end

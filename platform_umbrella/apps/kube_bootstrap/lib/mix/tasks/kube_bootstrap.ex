defmodule Mix.Tasks.Kube.Bootstrap do
  @shortdoc "Bootstrap resources into a kubernetes cluster"

  use Mix.Task

  require Logger
  alias CommonCore.StateSummary

  @requirements ["app.config"]

  @start_apps [:common_core, :logger, :k8s, :kube_bootstrap]

  def run(args) do
    [path] = args

    load_apps()

    {:ok, summary} = read_summary(path)
    KubeBootstrap.bootstrap_from_summary(summary)
  end

  # From a path to an install spec file, read the summary
  defp read_summary(path) do
    with {:ok, file_contents} <- File.read(path),
         {:ok, decoded_content} <- Jason.decode(file_contents) do
      # We are bootstrapping from an install spec file
      # the bootstrap job will only get the summary
      summary_content = Map.get(decoded_content, "target_summary")

      # Decode everything from string keyed map to struct
      StateSummary.new(summary_content)
    else
      {:error, _} = error -> error
    end
  end

  defp load_apps do
    Logger.debug("Ensuring app is started")

    Enum.each(@start_apps, fn app ->
      {:ok, _apps} = Application.ensure_all_started(app, :permanent)
    end)

    :ok
  end
end

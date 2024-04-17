defmodule Mix.Tasks.Kube.Bootstrap do
  @shortdoc "Bootstrap resources into a kubernetes cluster"

  use Mix.Task

  require Logger

  @requirements ["app.config"]

  @start_apps [:common_core, :logger, :k8s, :kube_bootstrap]

  def run(args) do
    [path] = args

    load_apps()

    {:ok, summary} = KubeBootstrap.read_summary(path)
    KubeBootstrap.bootstrap_from_summary(summary)
  end

  defp load_apps do
    Logger.debug("Ensuring app is started")

    {:ok, _apps} = Application.ensure_all_started(@start_apps, :permanent)

    :ok
  end
end

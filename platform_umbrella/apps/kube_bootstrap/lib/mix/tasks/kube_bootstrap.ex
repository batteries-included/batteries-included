defmodule Mix.Tasks.Kube.Bootstrap do
  @shortdoc "Bootstrap resources into a kubernetes cluster"

  @moduledoc """
  Mix task to bootstrap resources into a Kubernetes cluster.
  This task reads a summary file and applies the
  resources defined within it to the Kubernetes cluster
  much like the bootstrap command in the docker image.
  """

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

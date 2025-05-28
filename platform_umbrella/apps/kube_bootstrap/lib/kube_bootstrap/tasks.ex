defmodule KubeBootstrap.Tasks do
  @moduledoc false
  @app :kube_bootstrap
  @start_apps [:common_core, :logger, :k8s, @app]

  def run do
    {:ok, _} = Application.ensure_all_started(@start_apps, :permanent)

    path = Application.fetch_env!(@app, :summary_path)

    {:ok, summary} = KubeBootstrap.read_summary(path)
    :ok = KubeBootstrap.bootstrap_from_summary(summary)
  end
end

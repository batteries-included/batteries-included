defmodule Server.Configs.Prometheus do
  @moduledoc """
  Prometheus configs. These will mostly be passed to the operator and turned into yml files in the ConfigMap.
  """
  import Ecto.Query, warn: false
  alias Server.Configs

  def base_config!(kube_cluster_id) do
    Configs.get_cluster_path!(kube_cluster_id, "/prometheus/base")
  end

  def create_for_cluster(kube_cluster_id) do
    Configs.create_raw_config(%{
      kube_cluster_id: kube_cluster_id,
      path: "/prometheus/base",
      content: %{
        "rule_files" => ["/etc/prometheus-rules/*"],
        "global" => %{"scrape_interval" => "15s"}
      }
    })
  end
end

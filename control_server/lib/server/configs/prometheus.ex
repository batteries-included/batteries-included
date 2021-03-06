defmodule Server.Configs.Prometheus do
  @moduledoc """
  Prometheus configs. These will mostly be passed to the operator and turned into yml files in the ConfigMap.
  """
  import Ecto.Query, warn: false
  alias Server.Configs

  def base_config! do
    Configs.get_by_path!("/prometheus/base")
  end

  def create do
    Configs.create_raw_config(%{
      path: "/prometheus/base",
      content: %{
        "rule_files" => ["/etc/prometheus-rules/*"],
        "global" => %{"scrape_interval" => "15s"}
      }
    })
  end
end

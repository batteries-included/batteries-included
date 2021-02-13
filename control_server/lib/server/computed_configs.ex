defmodule Server.ComputedConfigs do
  @moduledoc """
  Rather than configs just in the db these will be configs that are
  computed in some way. For example we could combine multiple configs.
  """
  alias Server.Configs
  alias Server.Configs.RawConfig

  def get(kube_cluster_id, "/prometheus/main" = path) do
    %RawConfig{} = base_config = Configs.get_cluster_path!(kube_cluster_id, "/prometheus/base")
    {:ok, %{path: path, contents: base_config.content}}
  end

  def get(kube_cluster_id, path) do
    {:ok, Configs.get_cluster_path!(kube_cluster_id, path)}
  end
end

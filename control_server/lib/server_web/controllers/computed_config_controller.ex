defmodule ServerWeb.ComputedConfigController do
  use ServerWeb, :controller

  alias Server.ComputedConfigs

  action_fallback ServerWeb.FallbackController

  def show(conn, %{"path" => paths, "kube_cluster_id" => kube_cluster_id}) do
    # the path is matched as a glob so it comes as a list of strings with no leading slash.
    # Recreate the full config path here.
    full_path = Path.join(["/"] ++ paths)
    {:ok, computed_config} = ComputedConfigs.get(kube_cluster_id, full_path)

    render(conn, "show.json", computed_config: computed_config)
  end
end

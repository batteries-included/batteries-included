defmodule ControlServerWeb.ComputedConfigController do
  use ControlServerWeb, :controller

  alias ControlServer.ComputedConfigs

  action_fallback ControlServerWeb.FallbackController

  def show(conn, %{"path" => paths}) do
    # the path is matched as a glob so it comes as a list of strings with no leading slash.
    # Recreate the full config path here.
    full_path = Path.join(["/"] ++ paths)
    {:ok, computed_config} = ComputedConfigs.get(full_path)

    render(conn, "show.json", computed_config: computed_config)
  end
end

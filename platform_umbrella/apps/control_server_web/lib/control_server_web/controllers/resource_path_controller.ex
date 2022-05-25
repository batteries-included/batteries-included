defmodule ControlServerWeb.ResourcePathController do
  use ControlServerWeb, :controller

  alias ControlServer.SnapshotApply

  action_fallback ControlServerWeb.FallbackController

  def index(conn, _params) do
    resource_paths = SnapshotApply.list_resource_paths()
    render(conn, "index.json", resource_paths: resource_paths)
  end

  def show(conn, %{"id" => id}) do
    resource_path = SnapshotApply.get_resource_path!(id)
    render(conn, "show.json", resource_path: resource_path)
  end
end

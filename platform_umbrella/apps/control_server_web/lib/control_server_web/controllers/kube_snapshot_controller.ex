defmodule ControlServerWeb.KubeSnapshotController do
  use ControlServerWeb, :controller

  alias ControlServer.SnapshotApply

  action_fallback ControlServerWeb.FallbackController

  def index(conn, _params) do
    kube_snapshots = SnapshotApply.list_kube_snapshots()
    render(conn, "index.json", kube_snapshots: kube_snapshots)
  end

  def show(conn, %{"id" => id}) do
    kube_snapshot = SnapshotApply.get_kube_snapshot!(id)
    render(conn, "show.json", kube_snapshot: kube_snapshot)
  end
end

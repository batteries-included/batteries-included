defmodule ControlServerWeb.KubeSnapshotView do
  use ControlServerWeb, :view
  alias ControlServerWeb.KubeSnapshotView

  def render("index.json", %{kube_snapshots: kube_snapshots}) do
    %{data: render_many(kube_snapshots, KubeSnapshotView, "kube_snapshot.json")}
  end

  def render("show.json", %{kube_snapshot: kube_snapshot}) do
    %{data: render_one(kube_snapshot, KubeSnapshotView, "kube_snapshot.json")}
  end

  def render("kube_snapshot.json", %{kube_snapshot: kube_snapshot}) do
    %{
      id: kube_snapshot.id,
      status: kube_snapshot.status
    }
  end
end

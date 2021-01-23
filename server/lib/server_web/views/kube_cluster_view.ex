defmodule ServerWeb.KubeClusterView do
  use ServerWeb, :view
  alias ServerWeb.KubeClusterView

  def render("index.json", %{kube_clusters: kube_clusters}) do
    %{data: render_many(kube_clusters, KubeClusterView, "kube_cluster.json")}
  end

  def render("show.json", %{kube_cluster: kube_cluster}) do
    %{data: render_one(kube_cluster, KubeClusterView, "kube_cluster.json")}
  end

  def render("kube_cluster.json", %{kube_cluster: kube_cluster}) do
    %{id: kube_cluster.id, external_uid: kube_cluster.external_uid, adopted: kube_cluster.adopted}
  end
end

defmodule Server.Clusters.KubeCluster do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "kube_clusters" do
    field :external_uid, :string

    timestamps()
  end

  def changeset(kube_cluster, attrs),
    do: do_changeset(kube_cluster, attrs, [:external_uid])

  def do_changeset(kube_cluster, attrs, allowed) do
    kube_cluster
    |> cast(attrs, allowed)
    |> validate_required(allowed)
  end
end

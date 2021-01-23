defmodule Server.Clusters.KubeCluster do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "kube_clusters" do
    field :adopted, :boolean, default: false
    field :external_uid, :string

    timestamps()
  end

  @doc false
  def changeset(kube_cluster, attrs) do
    kube_cluster
    |> cast(attrs, [:external_uid])
    |> validate_required([:external_uid])
  end
end

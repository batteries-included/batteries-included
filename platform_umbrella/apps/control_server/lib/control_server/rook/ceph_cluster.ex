defmodule ControlServer.Rook.CephCluster do
  use TypedEctoSchema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "ceph_clusters" do
    field :data_dir_host_path, :string
    field :name, :string
    field :namespace, :string, default: "battery-data"
    embeds_many :nodes, ControlServer.Rook.CephStorageNode, on_replace: :delete
    field :num_mgr, :integer, default: 1
    field :num_mon, :integer, default: 1

    timestamps()
  end

  @doc false
  def changeset(ceph_cluster, attrs) do
    ceph_cluster
    |> cast(attrs, [:name, :num_mon, :num_mgr, :data_dir_host_path])
    |> cast_embed(:nodes)
    |> validate_required([:name, :namespace, :num_mon, :num_mgr, :data_dir_host_path])
    |> unique_constraint(:name)
    |> unique_constraint(:namespace)
  end
end

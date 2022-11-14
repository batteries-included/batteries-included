defmodule ControlServer.Rook.CephFilesystem do
  use TypedEctoSchema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "ceph_filesystems" do
    field :name, :string
    field :include_erasure_encoded, :boolean, default: true

    timestamps()
  end

  def changeset(ceph_filesystem, attrs) do
    ceph_filesystem
    |> cast(attrs, [:name, :include_erasure_encoded])
    |> validate_required([:name])
  end
end

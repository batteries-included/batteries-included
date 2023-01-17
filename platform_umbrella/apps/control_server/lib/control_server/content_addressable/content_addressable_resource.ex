defmodule ControlServer.ContentAddressable.ContentAddressableResource do
  use TypedEctoSchema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "content_addressable_resources" do
    field :hash, :string
    field :value, :map, redact: true

    has_many :resource_paths, ControlServer.SnapshotApply.ResourcePath
    has_many :deleted_resources, ControlServer.Stale.DeletedResource

    timestamps()
  end

  def hash_to_uuid!(bin) do
    {:ok, uuid} = hash_to_uuid(bin)
    uuid
  end

  def hash_to_uuid(bin) do
    bin
    |> Base.decode32!()
    |> :binary.bin_to_list()
    |> Enum.chunk_every(2)
    |> Enum.map(fn [a, b] -> Bitwise.bxor(a, b) end)
    |> :binary.list_to_bin()
    |> Ecto.UUID.load()
  end

  @doc false
  def changeset(content_addressable_resource, attrs) do
    content_addressable_resource
    |> cast(attrs, [:id, :value, :hash])
    |> validate_required([:value, :hash])
  end
end

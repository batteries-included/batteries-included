defmodule ControlServer.ContentAddressable.Document do
  @moduledoc false

  use CommonCore, :schema

  @derive {
    Flop.Schema,
    filterable: [],
    sortable: [:inserted_at, :id],
    default_limit: 12,
    default_order: %{
      order_by: [:inserted_at, :id],
      order_directions: [:desc, :desc]
    }
  }

  batt_schema "documents" do
    field :hash, :string
    field :value, :map, redact: true

    has_many :resource_paths, ControlServer.SnapshotApply.ResourcePath
    has_many :keycloak_actions, ControlServer.SnapshotApply.KeycloakAction
    has_many :deleted_resources, ControlServer.Deleted.DeletedResource

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
    |> CommonCore.Ecto.BatteryUUID.load()
  end
end

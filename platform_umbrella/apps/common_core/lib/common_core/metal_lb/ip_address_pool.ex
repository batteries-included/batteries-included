defmodule CommonCore.MetalLB.IPAddressPool do
  @moduledoc false

  use CommonCore, :schema

  @derive {
    Flop.Schema,
    filterable: [:name], sortable: [:id, :name, :subnet]
  }

  @required_fields [:name, :subnet]
  @read_only_fields ~w(name)a

  batt_schema "ip_address_pools" do
    slug_field :name
    field :subnet, :string

    timestamps()
  end

  @doc false
  def changeset(ip_address_pool, attrs \\ %{}, opts \\ []) do
    ip_address_pool
    |> CommonCore.Ecto.Schema.schema_changeset(attrs, opts)
    |> unique_constraint(:name)
  end

  def validate(params) do
    changeset =
      %__MODULE__{}
      |> changeset(params)
      |> Map.put(:action, :validate)

    data = Ecto.Changeset.apply_changes(changeset)

    {changeset, data}
  end

  def to_fresh_ip_address_pool(%{} = args) do
    clean_args = Map.drop(args, [:id, :inserted_at, :updated_at])

    %__MODULE__{}
    |> changeset(clean_args)
    |> Ecto.Changeset.apply_action!(:create)
  end
end

defmodule CommonCore.FerretDB.FerretService do
  @moduledoc false
  use CommonCore, :schema

  import CommonCore.Util.EctoValidations

  alias CommonCore.Util.Memory

  @required_fields ~w(name instances postgres_cluster_id)a
  @optional_fields ~w(cpu_requested cpu_limits memory_requested memory_limits virtual_size)a

  @presets [
    %{
      name: "tiny",
      cpu_requested: 100,
      cpu_limits: 500,
      memory_requested: Memory.mb_to_bytes(128),
      memory_limits: Memory.mb_to_bytes(512)
    },
    %{
      name: "small",
      cpu_requested: 500,
      cpu_limits: 1000,
      memory_requested: Memory.mb_to_bytes(512),
      memory_limits: Memory.mb_to_bytes(1024)
    },
    %{
      name: "large",
      cpu_requested: 4000,
      cpu_limits: 4000,
      memory_requested: Memory.gb_to_bytes(2),
      memory_limits: Memory.gb_to_bytes(2)
    },
    %{
      name: "huge",
      cpu_requested: 8000,
      cpu_limits: 8000,
      memory_requested: Memory.gb_to_bytes(24),
      memory_limits: Memory.gb_to_bytes(24)
    }
  ]

  typed_schema "ferret_services" do
    field :name, :string
    field :instances, :integer
    field :cpu_requested, :integer
    field :cpu_limits, :integer
    field :memory_requested, :integer
    field :memory_limits, :integer

    belongs_to :postgres_cluster, CommonCore.Postgres.Cluster

    # Used in the CRUD form. User picks a "Size", which sets other fields based on presets.
    field :virtual_size, :string, virtual: true

    timestamps()
  end

  def presets, do: @presets

  def preset_by_name(name), do: Enum.find(@presets, fn p -> p.name == name end)

  def preset_options_for_select, do: Enum.map(@presets, &{String.capitalize(&1.name), &1.name}) ++ [{"Custom", "custom"}]

  @doc false
  def changeset(ferret_service, attrs) do
    fields = @required_fields ++ @optional_fields

    ferret_service
    |> cast(attrs, fields)
    |> maybe_fill_in_slug(:name)
    |> downcase_fields([:name])
    |> maybe_set_virtual_size(@presets)
    |> validate_dns_label(:name)
    |> validate_required(@required_fields)
  end
end

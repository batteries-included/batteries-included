defmodule CommonCore.FerretDB.FerretService do
  @moduledoc false

  use CommonCore, {:schema, no_encode: [:project, :postgres_cluster]}

  alias CommonCore.Projects.Project
  alias CommonCore.Util.Memory

  @derive {
    Flop.Schema,
    filterable: [:name], sortable: [:id, :name, :instances]
  }

  @required_fields ~w(instances postgres_cluster_id)a
  @read_only_fields ~w(name)a

  @presets [
    %{
      name: "tiny",
      cpu_requested: 100,
      cpu_limits: 500,
      memory_requested: Memory.to_bytes(128, :MB),
      memory_limits: Memory.to_bytes(512, :MB)
    },
    %{
      name: "small",
      cpu_requested: 500,
      cpu_limits: 1000,
      memory_requested: Memory.to_bytes(512, :MB),
      memory_limits: Memory.to_bytes(1024, :MB)
    },
    %{
      name: "large",
      cpu_requested: 4000,
      cpu_limits: 4000,
      memory_requested: Memory.to_bytes(2, :GB),
      memory_limits: Memory.to_bytes(2, :GB)
    },
    %{
      name: "huge",
      cpu_requested: 8000,
      cpu_limits: 8000,
      memory_requested: Memory.to_bytes(24, :GB),
      memory_limits: Memory.to_bytes(24, :GB)
    }
  ]

  @required_fields ~w(name instances)a

  batt_schema "ferret_services" do
    slug_field :name
    field :instances, :integer, default: 1
    field :cpu_requested, :integer
    field :cpu_limits, :integer
    field :memory_requested, :integer
    field :memory_limits, :integer

    belongs_to :postgres_cluster, CommonCore.Postgres.Cluster

    # Used in the CRUD form. User picks a "Size", which sets other fields based on presets.
    field :virtual_size, CommonCore.Size, virtual: true

    belongs_to :project, Project

    timestamps()
  end

  def presets, do: @presets

  def preset_by_name(name), do: Enum.find(@presets, fn p -> p.name == name end)

  def preset_options, do: Enum.map(@presets, &{String.capitalize(&1.name), &1.name}) ++ [{"Custom", "custom"}]

  @doc false
  def changeset(ferret_service, attrs, opts \\ []) do
    ferret_service
    |> CommonCore.Ecto.Schema.schema_changeset(attrs, opts)
    |> maybe_set_virtual_size(@presets)
    |> foreign_key_constraint(:project_id)
  end
end

defmodule CommonCore.Redis.FailoverCluster do
  @moduledoc false

  use CommonCore, {:schema, no_encode: [:project]}

  alias CommonCore.Projects.Project
  alias CommonCore.Util.Memory

  @derive {
    Flop.Schema,
    filterable: [:name], sortable: [:id, :name, :num_redis_instances, :num_sentinel_instances, :memory_limits]
  }

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
      memory_requested: Memory.to_bytes(1, :GB),
      memory_limits: Memory.to_bytes(1, :GB)
    }
  ]

  @required_fields ~w(type name)a

  batt_schema "redis_clusters" do
    slug_field :name

    field :num_redis_instances, :integer, default: 1
    field :num_sentinel_instances, :integer
    field :cpu_requested, :integer
    field :cpu_limits, :integer
    field :memory_requested, :integer
    field :memory_limits, :integer

    field :type, Ecto.Enum, values: [:standard, :internal], default: :standard

    # Used in the CRUD form. User picks a "Size", which sets other fields based on presets.
    field :virtual_size, :string, virtual: true

    belongs_to :project, Project

    timestamps()
  end

  def presets, do: @presets

  def preset_by_name(name) do
    Enum.find(@presets, fn preset -> preset.name == name end)
  end

  def preset_options_for_select, do: Enum.map(@presets, &{String.capitalize(&1.name), &1.name}) ++ [{"Custom", "custom"}]

  @doc false
  def changeset(failover_cluster, attrs) do
    failover_cluster
    |> CommonCore.Ecto.Schema.schema_changeset(attrs)
    |> maybe_set_virtual_size(@presets)
    |> unique_constraint([:type, :name])
    |> foreign_key_constraint(:project_id)
  end

  def validate(params) do
    changeset =
      %__MODULE__{}
      |> changeset(params)
      |> Map.put(:action, :validate)

    data = Ecto.Changeset.apply_changes(changeset)

    {changeset, data}
  end

  def to_fresh_cluster(%{} = args) do
    clean_args = Map.delete(args, :id)

    %__MODULE__{}
    |> changeset(clean_args)
    |> Ecto.Changeset.apply_action!(:create)
  end
end

defmodule CommonCore.Postgres.Cluster do
  @moduledoc false

  use CommonCore, {:schema, no_encode: [:project]}

  alias CommonCore.Projects.Project
  alias CommonCore.Util.Memory

  @presets [
    %{
      name: "tiny",
      storage_size: Memory.to_bytes(512, :MB),
      cpu_requested: 500,
      cpu_limits: 500,
      memory_requested: Memory.to_bytes(512, :MB),
      memory_limits: Memory.to_bytes(512, :MB)
    },
    %{
      name: "small",
      storage_size: Memory.to_bytes(16, :GB),
      cpu_requested: 500,
      cpu_limits: 2000,
      memory_requested: Memory.to_bytes(1, :GB),
      memory_limits: Memory.to_bytes(4, :GB)
    },
    %{
      name: "medium",
      storage_size: Memory.to_bytes(64, :GB),
      cpu_requested: 4000,
      cpu_limits: 4000,
      memory_requested: Memory.to_bytes(8, :GB),
      memory_limits: Memory.to_bytes(8, :GB)
    },
    %{
      name: "large",
      storage_size: Memory.to_bytes(128, :GB),
      cpu_requested: 8000,
      cpu_limits: 8000,
      memory_requested: Memory.to_bytes(16, :GB),
      memory_limits: Memory.to_bytes(16, :GB)
    },
    %{
      name: "xlarge",
      storage_size: Memory.to_bytes(256, :GB),
      cpu_requested: 10_000,
      cpu_limits: 10_000,
      memory_requested: Memory.to_bytes(32, :GB),
      memory_limits: Memory.to_bytes(32, :GB)
    },
    %{
      name: "huge",
      storage_size: Memory.to_bytes(1024, :GB),
      cpu_requested: 32_000,
      cpu_limits: 32_000,
      memory_requested: Memory.to_bytes(256, :GB),
      memory_limits: Memory.to_bytes(256, :GB)
    }
  ]

  @required_fields ~w(name num_instances type)a

  batt_schema "pg_clusters" do
    slug_field :name
    field :num_instances, :integer, default: 1
    field :type, Ecto.Enum, values: [:standard, :internal], default: :standard
    field :storage_size, :integer
    field :storage_class, :string
    field :cpu_requested, :integer
    field :cpu_limits, :integer
    field :memory_requested, :integer
    field :memory_limits, :integer

    # Used in the CRUD form. User picks a "Size", which sets other fields based on presets.
    field :virtual_size, :string, virtual: true

    # Used in the CRUD form. A range input value that gets converted into the storage size in bytes.
    field :virtual_storage_size_range_value, :integer, virtual: true

    embeds_many :users, CommonCore.Postgres.PGUser, on_replace: :delete
    embeds_one :database, CommonCore.Postgres.PGDatabase, on_replace: :delete

    belongs_to :project, Project

    timestamps()
  end

  @doc false
  def changeset(cluster, attrs, range_ticks \\ nil) do
    cluster
    |> CommonCore.Ecto.Schema.schema_changeset(attrs)
    |> maybe_set_virtual_size(@presets)
    |> put_range_value_from_storage_size(range_ticks || storage_range_ticks())
    |> validate_number(:cpu_requested, greater_than: 0, less_than: 100_000)
    |> validate_number(:cpu_limits, greater_than: 0, less_than: 100_000)
    |> validate_inclusion(:memory_requested, memory_options())
    |> validate_inclusion(:memory_limits, memory_options())
    |> unique_constraint([:type, :name])
    |> foreign_key_constraint(:project_id)
    |> validate_required([:storage_size])
    |> validate_storage_size()
  end

  def put_storage_size(changeset, range_value, range_ticks \\ nil) do
    changeset
    |> put_storage_size_from_range_value(range_value, range_ticks || storage_range_ticks())
    |> validate_storage_size()
  end

  defp put_storage_size_from_range_value(changeset, range_value, range_ticks) when is_binary(range_value) do
    case Float.parse(range_value) do
      {bytes, _} -> put_storage_size_from_range_value(changeset, round(bytes), range_ticks)
      :error -> add_error(changeset, :storage_size, "can't parse value")
    end
  end

  defp put_storage_size_from_range_value(changeset, range_value, range_ticks) do
    storage_size = Memory.range_value_to_bytes(range_value, range_ticks)

    changeset
    |> put_change(:storage_size, storage_size)
    |> put_change(:virtual_storage_size_range_value, range_value)
  end

  defp put_range_value_from_storage_size(changeset, range_ticks) do
    if storage_size = get_field(changeset, :storage_size) do
      range_value = Memory.bytes_to_range_value(storage_size, range_ticks)

      put_change(changeset, :virtual_storage_size_range_value, range_value)
    else
      put_change(changeset, :virtual_storage_size_range_value, 0)
    end
  end

  defp validate_storage_size(changeset) do
    validate_change(changeset, :storage_size, fn :storage_size, storage_size ->
      current_size = changeset.data.storage_size

      if current_size && storage_size < current_size do
        put_storage_size_error(changeset, "can't decrease storage size from #{Memory.humanize(current_size)}")
      else
        []
      end
    end)
  end

  defp put_storage_size_error(changeset, message) do
    if get_field(changeset, :virtual_size) == "custom" do
      [storage_size: message]
    else
      [virtual_size: message]
    end
  end

  def preset_options_for_select do
    Enum.map(@presets, &{String.capitalize(&1.name), &1.name}) ++ [{"Custom", "custom"}]
  end

  def storage_range_ticks do
    [
      {"500MB", 0},
      {"1GB", 0.1},
      {"50GB", 0.2},
      {"250GB", 0.4},
      {"500GB", 0.6},
      {"1TB", 0.8},
      {"2TB", 1}
    ]
  end

  def compact_storage_range_ticks do
    [
      {"500MB", 0},
      {"1GB", 0.15},
      {"50GB", 0.3},
      {"250GB", 0.65},
      {"1TB", 1}
    ]
  end

  def cpu_select_options do
    [
      {"None", nil},
      {"0.05 cores", 50},
      {"0.1 cores", 100},
      {"0.2 cores", 200},
      {"0.5 cores", 500},
      {"1 core", 1000},
      {"2 cores", 2000},
      {"4 cores", 4000},
      {"8 cores", 8000},
      {"16 cores", 16_000},
      {"24 cores", 24_000},
      {"32 cores", 32_000}
    ]
  end

  def memory_options do
    [
      Memory.to_bytes(512, :MB),
      Memory.to_bytes(1, :GB),
      Memory.to_bytes(2, :GB),
      Memory.to_bytes(4, :GB),
      Memory.to_bytes(8, :GB),
      Memory.to_bytes(16, :GB),
      Memory.to_bytes(32, :GB),
      Memory.to_bytes(64, :GB),
      Memory.to_bytes(128, :GB),
      Memory.to_bytes(256, :GB),
      Memory.to_bytes(512, :GB),
      Memory.to_bytes(1024, :GB)
    ]
  end
end

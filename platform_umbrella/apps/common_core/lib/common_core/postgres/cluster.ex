defmodule CommonCore.Postgres.Cluster do
  @moduledoc """
  The postgres cluster module
  """
  use TypedEctoSchema

  import CommonCore.Util.EctoValidations
  import Ecto.Changeset

  alias CommonCore.Util.Memory

  require Logger

  @presets [
    %{
      name: "small",
      storage_size: Memory.mb_to_bytes(512),
      cpu_requested: 100,
      cpu_limits: 500,
      memory_requested: Memory.mb_to_bytes(512),
      memory_limits: Memory.mb_to_bytes(1024)
    },
    %{
      name: "medium",
      storage_size: Memory.gb_to_bytes(64),
      cpu_requested: 500,
      cpu_limits: 2000,
      memory_requested: Memory.gb_to_bytes(2),
      memory_limits: Memory.gb_to_bytes(4)
    },
    %{
      name: "large",
      storage_size: Memory.gb_to_bytes(256),
      cpu_requested: 2000,
      cpu_limits: 4000,
      memory_requested: Memory.gb_to_bytes(8),
      memory_limits: Memory.gb_to_bytes(16)
    },
    %{
      name: "huge",
      storage_size: Memory.gb_to_bytes(1024),
      cpu_requested: 4000,
      cpu_limits: 8000,
      memory_requested: Memory.gb_to_bytes(32),
      memory_limits: Memory.gb_to_bytes(64)
    }
  ]

  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "pg_clusters" do
    field :name, :string
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

    timestamps()
  end

  @doc false
  def changeset(cluster, attrs) do
    cluster
    |> cast(attrs, [
      :name,
      :num_instances,
      :type,
      :storage_size,
      :storage_class,
      :cpu_requested,
      :cpu_limits,
      :memory_requested,
      :memory_limits,
      :virtual_size,
      :virtual_storage_size_range_value
    ])
    |> maybe_set_virtual_size()
    |> maybe_convert_virtual_size_to_presets()
    |> maybe_set_storage_size_slider_value()
    |> cast_embed(:users)
    |> cast_embed(:database)
    |> validate_required([
      :name,
      :storage_size,
      :num_instances,
      :type
    ])
    |> validate_number(:cpu_requested, greater_than: 0, less_than: 100_000)
    |> validate_number(:cpu_limits, greater_than: 0, less_than: 100_000)
    |> validate_inclusion(:memory_requested, memory_options())
    |> validate_inclusion(:memory_limits, memory_limits_options())
    |> downcase_fields([:name])
    |> validate_length(:name, min: 1, max: 128)
    |> unique_constraint([:type, :name])
  end

  def validate(cluster \\ %__MODULE__{}, params) do
    changeset =
      cluster
      |> changeset(params)
      |> Map.put(:action, :validate)

    data = Ecto.Changeset.apply_changes(changeset)

    {changeset, data}
  end

  def to_fresh_cluster(%{} = args) do
    clean_args = Map.drop(args, [:id])

    %__MODULE__{}
    |> changeset(clean_args)
    |> Ecto.Changeset.apply_action!(:create)
  end

  def cpu_select_options,
    do: [
      {"0.05 cores", 50},
      {"0.1 cores", 100},
      {"0.2 cores", 200},
      {"0.5 cores", 500},
      {"1 core", 1000},
      {"2 cores", 2000},
      {"4 cores", 4000},
      {"8 cores", 8000},
      {"16 cores", 16_000}
    ]

  def memory_options,
    do: [
      Memory.mb_to_bytes(512),
      Memory.gb_to_bytes(1),
      Memory.gb_to_bytes(2),
      Memory.gb_to_bytes(4),
      Memory.gb_to_bytes(8),
      Memory.gb_to_bytes(16),
      Memory.gb_to_bytes(32),
      Memory.gb_to_bytes(64),
      Memory.gb_to_bytes(128),
      Memory.gb_to_bytes(256),
      Memory.gb_to_bytes(512),
      Memory.gb_to_bytes(1024)
    ]

  def memory_limits_options, do: memory_options()
  def preset_options, do: @presets
  def preset_options_for_select, do: Enum.map(@presets, &{String.capitalize(&1.name), &1.name}) ++ [{"Custom", "custom"}]

  def get_preset(preset), do: Enum.find(@presets, &(&1.name == preset))

  def maybe_set_virtual_size(changeset) do
    storage_size = get_field(changeset, :storage_size)
    virtual_size = get_field(changeset, :virtual_size)

    if storage_size && !virtual_size do
      put_change(changeset, :virtual_size, calculate_virtual_size(storage_size))
    else
      changeset
    end
  end

  def maybe_convert_virtual_size_to_presets(changeset) do
    convert_virtual_size_to_presets(changeset, get_field(changeset, :virtual_size))
  end

  defp maybe_set_storage_size_slider_value(changeset) do
    storage_size = get_field(changeset, :storage_size)
    virtual_storage_size_range_value = get_field(changeset, :virtual_storage_size_range_value)

    if storage_size && !virtual_storage_size_range_value do
      put_change(
        changeset,
        :virtual_storage_size_range_value,
        CommonCore.Util.MemorySliderConverter.bytes_to_slider_value(storage_size)
      )
    else
      changeset
    end
  end

  def convert_virtual_size_to_presets(changeset, nil), do: changeset

  def convert_virtual_size_to_presets(changeset, "custom") do
    case get_field(changeset, :storage_size) do
      nil ->
        # When switching to "custom" in the form, we set some defaults to start with:
        starting_point_preset = get_preset("medium")

        slider_value =
          CommonCore.Util.MemorySliderConverter.bytes_to_slider_value(starting_point_preset.storage_size)

        changeset
        |> set_preset(starting_point_preset)
        |> put_change(:virtual_storage_size_range_value, slider_value)

      _ ->
        changeset
    end
  end

  def convert_virtual_size_to_presets(changeset, virtual_size) do
    preset = get_preset(virtual_size)
    set_preset(changeset, preset)
  end

  def calculate_virtual_size(storage_size) do
    case Enum.find(@presets, &(&1.storage_size == storage_size)) do
      nil ->
        "custom"

      preset ->
        preset.name
    end
  end

  defp set_preset(changeset, preset) do
    changeset
    |> put_change(:storage_size, preset[:storage_size])
    |> put_change(:cpu_requested, preset[:cpu_requested])
    |> put_change(:cpu_limits, preset[:cpu_limits])
    |> put_change(:memory_requested, preset[:memory_requested])
    |> put_change(:memory_limits, preset[:memory_limits])
  end
end

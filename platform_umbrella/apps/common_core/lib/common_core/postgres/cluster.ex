defmodule CommonCore.Postgres.Cluster do
  @moduledoc """
  The postgres cluster module
  """
  use TypedEctoSchema

  import CommonCore.Util.EctoValidations
  import Ecto.Changeset

  alias CommonCore.Projects.Project
  alias CommonCore.Util.Memory
  alias CommonCore.Util.MemorySliderConverter

  require Logger

  @required_fields ~w(name storage_size num_instances type)a
  @optional_fields ~w(storage_class cpu_requested cpu_limits memory_requested memory_limits virtual_size virtual_storage_size_range_value project_id)a

  @presets [
    %{
      name: "tiny",
      storage_size: Memory.mb_to_bytes(512),
      cpu_requested: 500,
      cpu_limits: 500,
      memory_requested: Memory.mb_to_bytes(512),
      memory_limits: Memory.mb_to_bytes(512)
    },
    %{
      name: "small",
      storage_size: Memory.gb_to_bytes(16),
      cpu_requested: 500,
      cpu_limits: 2000,
      memory_requested: Memory.gb_to_bytes(1),
      memory_limits: Memory.gb_to_bytes(4)
    },
    %{
      name: "medium",
      storage_size: Memory.gb_to_bytes(64),
      cpu_requested: 4000,
      cpu_limits: 4000,
      memory_requested: Memory.gb_to_bytes(8),
      memory_limits: Memory.gb_to_bytes(8)
    },
    %{
      name: "large",
      storage_size: Memory.gb_to_bytes(128),
      cpu_requested: 8000,
      cpu_limits: 8000,
      memory_requested: Memory.gb_to_bytes(16),
      memory_limits: Memory.gb_to_bytes(16)
    },
    %{
      name: "xlarge",
      storage_size: Memory.gb_to_bytes(256),
      cpu_requested: 10_000,
      cpu_limits: 10_000,
      memory_requested: Memory.gb_to_bytes(32),
      memory_limits: Memory.gb_to_bytes(32)
    },
    %{
      name: "huge",
      storage_size: Memory.gb_to_bytes(1024),
      cpu_requested: 32_000,
      cpu_limits: 32_000,
      memory_requested: Memory.gb_to_bytes(256),
      memory_limits: Memory.gb_to_bytes(256)
    }
  ]

  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, except: [:__meta__, :project]}
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

    belongs_to :project, Project

    timestamps()
  end

  @doc false
  def changeset(cluster, attrs) do
    fields = Enum.concat(@required_fields, @optional_fields)

    cluster
    |> cast(attrs, fields)
    |> maybe_fill_in_slug(:name)
    |> downcase_fields([:name])
    |> maybe_set_virtual_size(@presets)
    |> maybe_set_storage_size_slider_value()
    |> cast_embed(:users)
    |> cast_embed(:database)
    |> validate_required(@required_fields)
    |> validate_dns_label(:name)
    |> validate_number(:cpu_requested, greater_than: 0, less_than: 100_000)
    |> validate_number(:cpu_limits, greater_than: 0, less_than: 100_000)
    |> validate_inclusion(:memory_requested, memory_options())
    |> validate_inclusion(:memory_limits, memory_limits_options())
    |> validate_length(:name, min: 1, max: 128)
    |> unique_constraint([:type, :name])
    |> foreign_key_constraint(:project_id)
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

  defp maybe_set_storage_size_slider_value(changeset) do
    storage_size = get_field(changeset, :storage_size)
    virtual_storage_size_range_value = get_field(changeset, :virtual_storage_size_range_value)

    if storage_size && !virtual_storage_size_range_value do
      put_change(
        changeset,
        :virtual_storage_size_range_value,
        MemorySliderConverter.bytes_to_slider_value(storage_size)
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
        slider_value = MemorySliderConverter.bytes_to_slider_value(starting_point_preset.storage_size)

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

  def put_storage_size_bytes(changeset, bytes) when is_binary(bytes) do
    bytes = if bytes == "", do: 0, else: String.to_integer(bytes)

    put_storage_size_bytes(changeset, bytes)
  end

  def put_storage_size_bytes(changeset, bytes) do
    value = MemorySliderConverter.bytes_to_slider_value(bytes)

    changeset
    |> put_change(:virtual_storage_size_range_value, value)
    |> put_change(:storage_size, bytes)
  end

  def put_storage_size_value(changeset, value) do
    bytes = convert_storage_slider_value_to_bytes(value)

    changeset
    |> put_change(:virtual_storage_size_range_value, value)
    |> put_change(:storage_size, bytes)
  end

  defp convert_storage_slider_value_to_bytes(range_value) when is_binary(range_value) do
    if range_value == "" do
      0
    else
      range_value
      |> String.to_integer()
      |> MemorySliderConverter.slider_value_to_bytes()
    end
  end

  defp convert_storage_slider_value_to_bytes(_), do: 1
end

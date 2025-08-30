defmodule CommonCore.Redis.RedisInstance do
  @moduledoc false

  use CommonCore, {:schema, no_encode: [:project, :replication_redis_instance, :sentinel_instances]}

  alias CommonCore.Projects.Project
  alias CommonCore.Util.Memory

  @derive {
    Flop.Schema,
    filterable: [:name], sortable: [:id, :name, :num_instances, :memory_limits]
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
  @read_only_fields ~w(name type)a

  batt_schema "redis_instances" do
    slug_field :name
    field :type, Ecto.Enum, values: [:standard, :internal], default: :standard

    # What kind of redis setup is this?
    #
    # - standalone: A single redis instance. No replication or clustering. Num instances is always 1.
    # - replication: A master and one or more slaves.
    # - sentinel: A set of processes that watch a redis replication setup and can failover to a new master if the current master fails.
    # - cluster: A cluster of redis instances with sharding and replication.
    field :instance_type, CommonCore.Redis.InstanceType, default: :standalone

    # Not used on :standalone
    field :num_instances, :integer, default: 1

    # Only used on :sentinel this will point to redis replication instances.
    belongs_to :replication_redis_instance, __MODULE__

    # Only used on :replication
    has_many :sentinel_instances, __MODULE__, foreign_key: :replication_redis_instance_id

    # Resources
    field :cpu_requested, :integer
    field :cpu_limits, :integer
    field :memory_requested, :integer
    field :memory_limits, :integer

    # Storage Info
    # If storage size is set then redis will get a persistent volume.
    field :storage_size, :integer
    field :storage_class, :string

    # Used in the CRUD form. User picks a "Size", which sets other fields based on presets.
    field :virtual_size, CommonCore.Size, virtual: true

    belongs_to :project, Project

    timestamps()
  end

  def presets, do: @presets

  def preset_by_name(name) do
    Enum.find(@presets, fn preset -> preset.name == name end)
  end

  def preset_options, do: Enum.map(@presets, &{String.capitalize(&1.name), &1.name}) ++ [{"Custom", "custom"}]

  # Note that Sentinel is not a valid option for the user to select.
  # that's until we have a proper ui for it.
  def type_options, do: Enum.map([:standalone, :replication, :cluster], &{String.capitalize(to_string(&1)), &1})

  @doc false
  def changeset(redis_instance, attrs, opts \\ []) do
    redis_instance
    |> CommonCore.Ecto.Schema.schema_changeset(attrs, opts)
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

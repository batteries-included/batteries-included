defmodule CommonCore.Redis.FailoverCluster do
  @moduledoc false
  use TypedEctoSchema

  import CommonCore.Util.EctoValidations
  import Ecto.Changeset

  alias CommonCore.Projects.Project
  alias CommonCore.Util.Memory

  @required_fields ~w(name type)a
  @optional_fields ~w(num_redis_instances num_sentinel_instances cpu_requested cpu_limits memory_requested memory_limits virtual_size project_id)a

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
      memory_requested: Memory.gb_to_bytes(1),
      memory_limits: Memory.gb_to_bytes(1)
    }
  ]

  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, except: [:__meta__, :project]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "redis_clusters" do
    field :name, :string

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
    fields = @required_fields ++ @optional_fields

    failover_cluster
    |> cast(attrs, fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:type, :name])
    |> foreign_key_constraint(:project_id)
    |> maybe_set_virtual_size(@presets)
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
    clean_args = Map.drop(args, [:id])

    %__MODULE__{}
    |> changeset(clean_args)
    |> Ecto.Changeset.apply_action!(:create)
  end
end

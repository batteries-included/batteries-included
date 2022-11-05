defmodule ControlServer.Redis.FailoverCluster do
  use TypedEctoSchema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "redis_clusters" do
    field :name, :string
    field :num_redis_instances, :integer
    field :num_sentinel_instances, :integer
    field :type, Ecto.Enum, values: [:standard, :internal], default: :standard

    timestamps()
  end

  def num_sentinel_instances(failover), do: Map.get(failover, :num_sentinel_instances, 1)
  def num_redis_instances(failover), do: Map.get(failover, :num_redis_instances, 1)

  @doc false
  def changeset(failover_cluster, attrs) do
    failover_cluster
    |> cast(attrs, [:name, :num_sentinel_instances, :num_redis_instances, :type])
    |> validate_required([:name, :num_redis_instances])
  end

  def validate(params) do
    changeset =
      %__MODULE__{}
      |> changeset(params)
      |> Map.put(:action, :validate)

    data = Ecto.Changeset.apply_changes(changeset)

    {changeset, data}
  end
end

defmodule CommonCore.Redis.FailoverCluster do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "redis_clusters" do
    field :name, :string
    field :num_redis_instances, :integer, default: 1
    field :num_sentinel_instances, :integer, default: 1
    field :type, Ecto.Enum, values: [:standard, :internal], default: :standard

    timestamps()
  end

  @doc false
  def changeset(failover_cluster, attrs) do
    failover_cluster
    |> cast(attrs, [:name, :num_sentinel_instances, :num_redis_instances, :type])
    |> validate_required([:name, :num_redis_instances])
    |> unique_constraint([:type, :name])
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

defmodule ControlServer.Redis.FailoverCluster do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "failover_clusters" do
    field :memory_request, :string
    field :name, :string
    field :num_redis_instances, :integer
    field :num_sentinel_instances, :integer

    timestamps()
  end

  @doc false
  def changeset(failover_cluster, attrs) do
    failover_cluster
    |> cast(attrs, [:name, :num_sentinel_instances, :num_redis_instances, :memory_request])
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

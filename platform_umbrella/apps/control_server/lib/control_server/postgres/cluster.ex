defmodule ControlServer.Postgres.Cluster do
  @moduledoc """
  The postgres cluster module
  """
  use TypedEctoSchema
  import Ecto.Changeset

  alias KubeRawResources.RawCluster

  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "clusters" do
    field :name, :string
    field :num_instances, :integer, default: 1
    field :postgres_version, :string, default: "13"
    field :team_name, :string, default: "pg"
    field :type, Ecto.Enum, values: [:standard, :internal], default: :standard
    field :storage_size, :string
    field :users, {:map, {:array, :string}}
    field :databases, {:map, :string}
    timestamps()
  end

  @doc false
  def changeset(cluster, attrs) do
    cluster
    |> cast(attrs, [
      :name,
      :num_instances,
      :postgres_version,
      :team_name,
      :type,
      :storage_size,
      :users,
      :databases
    ])
    |> validate_required([
      :name,
      :postgres_version,
      :storage_size,
      :num_instances,
      :type,
      :team_name
    ])
    |> validate_format(:storage_size, ~r/^(\d+(e\d+)?|\d+(\.\d+)?(e\d+)?[EPTGMK]i?)$/,
      message: "Must be in the format [Number](EPTGMK)"
    )
    |> unique_constraint([:type, :team_name, :name])
  end

  def validate(params) do
    changeset =
      %__MODULE__{}
      |> changeset(params)
      |> Map.put(:action, :validate)

    data = Ecto.Changeset.apply_changes(changeset)

    {changeset, data}
  end

  defdelegate team_name(cluster), to: RawCluster
  defdelegate full_name(cluster), to: RawCluster
end

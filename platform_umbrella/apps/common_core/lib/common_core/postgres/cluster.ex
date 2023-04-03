defmodule CommonCore.Postgres.Cluster do
  @moduledoc """
  The postgres cluster module
  """
  use TypedEctoSchema
  import Ecto.Changeset

  require Logger

  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "pg_clusters" do
    field :name, :string
    field :num_instances, :integer, default: 1
    field :postgres_version, :string, default: "14"
    field :team_name, :string, default: "pg"
    field :type, Ecto.Enum, values: [:standard, :internal], default: :standard
    field :storage_size, :string
    embeds_many :users, CommonCore.Postgres.PGUser, on_replace: :delete
    embeds_many :databases, CommonCore.Postgres.PGDatabase, on_replace: :delete
    embeds_many :credential_copies, CommonCore.Postgres.PGCredentialCopy, on_replace: :delete
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
      :storage_size
    ])
    |> cast_embed(:users)
    |> cast_embed(:databases)
    |> cast_embed(:credential_copies)
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

  def to_fresh_cluster(%{} = args) do
    clean_args = Map.drop(args, [:id])

    %__MODULE__{}
    |> changeset(clean_args)
    |> Ecto.Changeset.apply_action!(:create)
  end
end

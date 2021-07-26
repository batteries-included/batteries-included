defmodule ControlServer.Postgres.Cluster do
  @moduledoc """
  The postgres cluster module
  """
  use Ecto.Schema
  import Ecto.Changeset
  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "clusters" do
    field :name, :string
    field :num_instances, :integer, default: 1
    field :postgres_version, :string
    field :size, :string
    timestamps()
  end

  @doc false
  def changeset(cluster, attrs) do
    cluster
    |> cast(attrs, [:name, :postgres_version, :size, :num_instances])
    |> validate_required([:name, :postgres_version, :size, :num_instances])
    |> unique_constraint(:name)
  end

  def validate(params) do
    changeset =
      %ControlServer.Postgres.Cluster{}
      |> changeset(params)
      |> Map.put(:action, :validate)

    data = Ecto.Changeset.apply_changes(changeset)

    {changeset, data}
  end
end

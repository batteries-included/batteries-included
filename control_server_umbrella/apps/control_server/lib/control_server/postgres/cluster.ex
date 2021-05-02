defmodule ControlServer.Postgres.Cluster do
  @moduledoc """
  The postgres cluster module
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "clusters" do
    field :name, :string
    field :num_instances, :integer
    field :postgres_version, :string
    field :size, :string

    timestamps()
  end

  @doc false
  def changeset(cluster, attrs) do
    cluster
    |> cast(attrs, [:name, :postgres_version, :size, :num_instances])
    |> validate_required([:name, :postgres_version, :size, :num_instances])
  end
end

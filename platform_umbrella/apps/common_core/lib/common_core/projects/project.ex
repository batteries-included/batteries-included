defmodule CommonCore.Projects.Project do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  @required_fields ~w(name type)a
  @optional_fields ~w(description)a

  @derive {Jason.Encoder, except: [:__meta__]}
  @timestamps_opts [type: :utc_datetime_usec]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "projects" do
    field :name, :string
    field :type, Ecto.Enum, values: [:web, :ai, :db]
    field :description, :string

    has_many :pg_clusters, CommonCore.Postgres.Cluster
    has_many :redis_clusters, CommonCore.Redis.FailoverCluster
    has_many :knative_services, CommonCore.Knative.Service

    timestamps()
  end

  def changeset(project, attrs) do
    fields = @required_fields ++ @optional_fields

    project
    |> cast(attrs, fields)
    |> validate_required(@required_fields)
    |> validate_length(:description, max: 1000)
  end

  def type_options_for_select do
    __MODULE__
    |> Ecto.Enum.values(:type)
    |> Enum.map(&{type_name(&1), &1})
  end

  def type_name(:web), do: "Web"
  def type_name(:ai), do: "Artificial Intelligence"
  def type_name(:db), do: "Database Only"
  def type_name(type), do: Atom.to_string(type)
end

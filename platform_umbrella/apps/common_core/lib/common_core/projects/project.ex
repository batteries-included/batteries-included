defmodule CommonCore.Projects.Project do
  @moduledoc false

  use CommonCore, :schema

  @required_fields ~w(name)a

  @derive {
    Flop.Schema,
    filterable: [:name], sortable: [:id, :name]
  }

  batt_schema "projects" do
    field :name, :string
    field :description, :string

    field :type, Ecto.Enum, values: [:ai, :web, :db, :bare], virtual: true

    has_many :postgres_clusters, CommonCore.Postgres.Cluster
    has_many :redis_clusters, CommonCore.Redis.FailoverCluster
    has_many :ferret_services, CommonCore.FerretDB.FerretService
    has_many :jupyter_notebooks, CommonCore.Notebooks.JupyterLabNotebook
    has_many :knative_services, CommonCore.Knative.Service
    has_many :traditional_services, CommonCore.TraditionalServices.Service

    timestamps()
  end

  def changeset(project, attrs) do
    project
    |> CommonCore.Ecto.Schema.schema_changeset(attrs)
    |> validate_length(:description, max: 1000)
    |> no_assoc_constraint(:postgres_clusters, name: :pg_clusters_project_id_fkey)
    |> no_assoc_constraint(:redis_clusters, name: :redis_clusters_project_id_fkey)
    |> no_assoc_constraint(:ferret_services, name: :ferret_services_project_id_fkey)
    |> no_assoc_constraint(:jupyter_notebooks, name: :jupyter_lab_notebooks_project_id_fkey)
    |> no_assoc_constraint(:knative_services, name: :knative_services_project_id_fkey)
    |> no_assoc_constraint(:traditional_services, name: :traditional_services_project_id_fkey)
  end

  def type_options_for_select do
    __MODULE__
    |> Ecto.Enum.values(:type)
    |> Enum.map(&{type_name(&1), &1})
  end

  def type_name(:ai), do: "AI"
  def type_name(:web), do: "Web"
  def type_name(:db), do: "Database Only"
  def type_name(:bare), do: "Bare Project"
  def type_name(type), do: Atom.to_string(type)

  def resource_types do
    [
      :postgres_clusters,
      :redis_clusters,
      :ferret_services,
      :jupyter_notebooks,
      :knative_services,
      :traditional_services
    ]
  end
end

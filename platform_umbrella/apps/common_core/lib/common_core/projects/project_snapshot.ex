defmodule CommonCore.Projects.ProjectSnapshot do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_embedded_schema do
    field :name, :string
    field :description, :string

    embeds_many :postgres_clusters, CommonCore.Postgres.Cluster
    embeds_many :ferret_services, CommonCore.FerretDB.FerretService
    embeds_many :redis_instances, CommonCore.Redis.RedisInstance
    embeds_many :jupyter_notebooks, CommonCore.Notebooks.JupyterLabNotebook
    embeds_many :knative_services, CommonCore.Knative.Service
    embeds_many :traditional_services, CommonCore.TraditionalServices.Service
    embeds_many :model_instances, CommonCore.Ollama.ModelInstance
  end

  @field_batteries %{
    postgres_clusters: :cloudnative_pg,
    ferret_services: :ferretdb,
    redis_instances: :redis,
    jupyter_notebooks: :notebooks,
    knative_services: :knative,
    traditional_services: :traditional_services,
    model_instances: :ollama
  }

  def required_batteries(snapshot) do
    # For each embed list in the project snapshot
    # return the needed battery if the list of embeds isn't empty.
    snapshot
    |> Map.from_struct()
    |> Map.take(Map.keys(@field_batteries))
    |> Enum.map(fn {field, embeds} ->
      if Enum.empty?(embeds) do
        nil
      else
        Map.get(@field_batteries, field)
      end
    end)
    |> Enum.filter(& &1)
  end
end

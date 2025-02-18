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
end

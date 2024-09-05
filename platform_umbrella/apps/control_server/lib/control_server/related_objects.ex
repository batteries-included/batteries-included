defmodule ControlServer.RelatedObjects do
  @moduledoc false

  use ControlServer, :context

  alias CommonCore.FerretDB.FerretService
  alias CommonCore.Knative.Service, as: KnativeService
  alias CommonCore.Notebooks.JupyterLabNotebook
  alias CommonCore.Postgres.Cluster
  alias CommonCore.Redis.RedisInstance
  alias CommonCore.TraditionalServices.Service, as: TraditionalService

  @doc """
  Given a project_id, return a list of all related object ids
  this is useful for getting all edit verions for a project
  """
  def related_ids(project_id) do
    ferret_service_ids = related_ids(project_id, FerretService)
    knative_service_ids = related_ids(project_id, KnativeService)
    jupyter_lab_notebook_ids = related_ids(project_id, JupyterLabNotebook)
    cluster_ids = related_ids(project_id, Cluster)
    redis_instance_ids = related_ids(project_id, RedisInstance)
    traditional_service_ids = related_ids(project_id, TraditionalService)

    [project_id]
    |> Enum.concat(ferret_service_ids)
    |> Enum.concat(knative_service_ids)
    |> Enum.concat(jupyter_lab_notebook_ids)
    |> Enum.concat(cluster_ids)
    |> Enum.concat(redis_instance_ids)
    |> Enum.concat(traditional_service_ids)
  end

  def related_ids(id, entity) do
    from(e in entity)
    |> where([e], e.project_id == ^id)
    |> select([e], e.id)
    |> Repo.all()
  end
end

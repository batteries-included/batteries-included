defmodule ControlServer.Projects.Snapshoter do
  @moduledoc false

  use ControlServer, :context

  alias CommonCore.ET.ProjectSnapshot
  alias CommonCore.Projects.Project
  alias Ecto.Multi

  @spec take_snapshot(Project.t()) :: {:ok, ProjectSnapshot.t()} | {:error, any()}

  def take_snapshot(%Project{} = project) do
    # We will create a snapshot of the project
    with {:ok, res} <- run_transaction(project) do
      # Add some fields
      values =
        res
        |> Map.put(:description, project.description)
        |> Map.put(:captured_at, DateTime.utc_now())

      {:ok, struct!(ProjectSnapshot, values)}
    end
  end

  def take_snapshot(project_id) do
    case ControlServer.Projects.get_project(project_id) do
      {:ok, project} -> take_snapshot(project)
      {:error, _} = error -> error
    end
  end

  defp run_transaction(project) do
    Project.resource_types()
    |> Enum.map(fn type ->
      {type, type_to_query(type, project.id)}
    end)
    |> Enum.filter(fn {_, query} -> query != nil end)
    |> Enum.reduce(Multi.new(), fn {type, q}, multi ->
      Multi.all(multi, type, q)
    end)
    |> Repo.transaction()
  end

  defp type_to_query(:postgres_clusters, project_id), do: query(CommonCore.Postgres.Cluster, project_id)

  defp type_to_query(:redis_instances, project_id), do: query(CommonCore.Redis.RedisInstance, project_id)

  defp type_to_query(:ferret_services, project_id), do: query(CommonCore.FerretDB.FerretService, project_id)

  defp type_to_query(:jupyter_notebooks, project_id), do: query(CommonCore.Notebooks.JupyterLabNotebook, project_id)

  defp type_to_query(:knative_services, project_id), do: query(CommonCore.Knative.Service, project_id)

  defp type_to_query(:traditional_services, project_id), do: query(CommonCore.TraditionalServices.Service, project_id)

  defp type_to_query(:model_instances, project_id), do: query(CommonCore.Ollama.ModelInstance, project_id)

  defp type_to_query(:ip_address_pools, _), do: nil

  defp type_to_query(_, _), do: nil

  defp query(module, project_id) do
    from(m in module, where: m.project_id == ^project_id)
  end
end

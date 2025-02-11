defmodule ControlServer.Projects.Snapshoter do
  @moduledoc false

  use ControlServer, :context

  alias CommonCore.FerretDB.FerretService
  alias CommonCore.MetalLB.IPAddressPool
  alias CommonCore.Notebooks.JupyterLabNotebook
  alias CommonCore.Ollama.ModelInstance
  alias CommonCore.Postgres.Cluster
  alias CommonCore.Projects.Project
  alias CommonCore.Projects.ProjectSnapshot
  alias CommonCore.Redis.RedisInstance
  alias Ecto.Multi

  @spec take_snapshot(Project.t()) :: {:ok, ProjectSnapshot.t()} | {:error, any()}

  def take_snapshot(%Project{} = project) do
    # We will create a snapshot of the project
    with {:ok, res} <- run_take_snap_transaction(project) do
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

  @spec apply_snapshot(Project.t(), ProjectSnapshot.t(), Keyword.t()) ::
          {:ok, any()} | {:error, any()}
  def apply_snapshot(project, snapshot, opts \\ []) do
    multi =
      Project.resource_types()
      |> Enum.reduce(Multi.new(), fn type, multi ->
        Multi.all(multi, type, get_by_name(project, snapshot, type))
      end)
      |> Multi.merge(fn context ->
        insert_multi(project, snapshot, context, opts)
      end)
      |> Multi.merge(fn context ->
        update_multi(project, snapshot, context, opts)
      end)

    Repo.transaction(multi)
  end

  defp run_take_snap_transaction(project) do
    Project.resource_types()
    |> Enum.map(fn type ->
      {type, resource_type_to_read_query(type, project.id)}
    end)
    |> Enum.filter(fn {_, query} -> query != nil end)
    |> Enum.reduce(Multi.new(), fn {type, q}, multi ->
      Multi.all(multi, type, q)
    end)
    |> Repo.transaction()
  end

  # For each resouce in the database that can have a row
  # create a query to read all of the rows for that resource
  # that are associated with the project
  defp resource_type_to_read_query(type, project_id) do
    case module_by_resouce_type(type) do
      nil -> nil
      module -> from(m in module, where: m.project_id == ^project_id)
    end
  end

  defp get_by_name(project, snapshot, type) do
    case module_by_resouce_type(type) do
      nil ->
        []

      module ->
        # Since names are unique we use them rather than ids, since the snapshot could
        # come from a different installation.
        names =
          snapshot
          |> Map.get(type, [])
          |> Enum.map(&Map.get(&1, :name))

        from(m in module, where: m.project_id == ^project.id and m.name in ^names)
    end
  end

  defp insert_multi(project, snapshot, context, _opts) do
    Enum.reduce(Project.resource_types(), Multi.new(), fn type, multi ->
      module = module_by_resouce_type(type)

      if module do
        # For this type we know all of the records by name
        existing_by_name = context |> Map.get(type) |> Map.new(fn m -> {m.name, m} end)

        snapshot
        |> Map.get(type, [])
        |> Enum.reject(fn m -> Map.has_key?(existing_by_name, m.name) end)
        |> Enum.reduce(multi, fn attrs, inner_multi ->
          attrs = attrs |> Map.put(:project_id, project.id) |> Map.put(:id, nil)

          changeset =
            apply(module, :changeset, [struct(module), prepare_for_insert(attrs, project)])

          Multi.insert(inner_multi, "insert_#{type}_#{attrs.name}", changeset)
        end)
      else
        multi
      end
    end)
  end

  defp update_multi(project, snapshot, context, _opts) do
    Enum.reduce(Project.resource_types(), Multi.new(), fn type, multi ->
      module = module_by_resouce_type(type)

      if module do
        # For this type we know all of the records by name
        existing_by_name = context |> Map.get(type) |> Map.new(fn m -> {m.name, m} end)

        snapshot
        |> Map.get(type, [])
        |> Enum.filter(fn m -> Map.has_key?(existing_by_name, m.name) end)
        |> Enum.reduce(multi, fn attrs, inner_multi ->
          existing = Map.get(existing_by_name, attrs.name)

          changeset = apply(module, :changeset, [existing, prepare_for_insert(attrs, project)])
          Multi.update(inner_multi, "update_#{type}_#{existing.name}", changeset)
        end)
      else
        multi
      end
    end)
  end

  defp prepare_for_insert(attrs, project) do
    attrs
    |> Map.from_struct()
    |> Map.put(:project_id, project.id)
    |> Map.delete(:id)
    |> Map.delete(:__meta__)
  end

  defp module_by_resouce_type(:postgres_clusters), do: Cluster

  defp module_by_resouce_type(:redis_instances), do: RedisInstance

  defp module_by_resouce_type(:ferret_services), do: FerretService

  defp module_by_resouce_type(:jupyter_notebooks), do: JupyterLabNotebook

  defp module_by_resouce_type(:knative_services), do: CommonCore.Knative.Service

  defp module_by_resouce_type(:traditional_services), do: CommonCore.TraditionalServices.Service

  defp module_by_resouce_type(:model_instances), do: ModelInstance

  defp module_by_resouce_type(:ip_address_pools), do: IPAddressPool

  defp module_by_resouce_type(_), do: nil
end

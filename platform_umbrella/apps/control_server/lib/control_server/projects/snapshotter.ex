defmodule ControlServer.Projects.Snapshoter do
  @moduledoc false

  use ControlServer, :context

  alias CommonCore.FerretDB.FerretService
  alias CommonCore.Knative.Service
  alias CommonCore.MetalLB.IPAddressPool
  alias CommonCore.Notebooks.JupyterLabNotebook
  alias CommonCore.Ollama.ModelInstance
  alias CommonCore.Postgres.Cluster
  alias CommonCore.Projects.Project
  alias CommonCore.Projects.ProjectSnapshot
  alias CommonCore.Redis.RedisInstance
  alias Ecto.Association.BelongsTo
  alias Ecto.Multi

  @spec take_snapshot(Project.t()) :: {:ok, ProjectSnapshot.t()} | {:error, any()}

  def take_snapshot(%Project{} = project) do
    # We will create a snapshot of the project
    with {:ok, res} <- run_take_snap_transaction(project) do
      # Add some fields
      values =
        res
        |> Map.put(:description, project.description)
        |> Map.put(:name, "Generated snapshot for project #{project.name}")

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
        Multi.all(multi, type, get_by_name_query(project, snapshot, type))
      end)
      |> Multi.merge(fn context ->
        insert_multi(project, snapshot, context, opts)
      end)
      |> Multi.merge(fn context ->
        update_multi(project, snapshot, context, opts)
      end)
      |> Multi.merge(fn context ->
        refetch_multi(project, snapshot, context, opts)
      end)
      |> Multi.merge(fn context ->
        fix_all_owner_references_multi(project, snapshot, context, opts)
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

  defp get_by_name_query(project, snapshot, type) do
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

  defp get_all_by_project_query(type, project_id) do
    case module_by_resouce_type(type) do
      nil -> []
      module -> from(m in module, where: m.project_id == ^project_id)
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
          attrs = Map.put(attrs, :id, nil)

          changeset =
            apply(module, :changeset, [struct(module), prepare_for_insert(module, attrs, project)])

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

          changeset =
            apply(module, :changeset, [existing, prepare_for_insert(module, attrs, project)])

          Multi.update(inner_multi, "update_#{type}_#{existing.name}", changeset)
        end)
      else
        multi
      end
    end)
  end

  # we need to know for sure what state all the resources are in after
  # insertion or updating. So we re-fetch all of them here.
  defp refetch_multi(project, _snapshot, _context, _opts) do
    Enum.reduce(Project.resource_types(), Multi.new(), fn type, multi ->
      Multi.all(multi, refetch_key(type), get_all_by_project_query(type, project.id))
    end)
  end

  # This is a beast of a function.
  # It will fix all of the owner references for the resources
  # that are in the snapshot. This is needed because we are
  # inserting the resources and their ID's might change or might not.
  defp fix_all_owner_references_multi(_project, snapshot, context, opts) do
    # We are going to fix all of the owner references for the types
    Enum.reduce(Project.resource_types(), Multi.new(), fn type, multi ->
      fix_type_owner_references_multi(snapshot, context, type, opts, multi)
    end)
  end

  # For a single type go through all the re-fetched resources
  # Check if they have any associations
  # If there are then find what they were in the snapshot
  # and set the new references by finding equivilant resources
  # in the other re-fetched resources
  defp fix_type_owner_references_multi(snapshot, context, type, _opts, multi) do
    module = module_by_resouce_type(type)
    assocs = get_associations(module)
    refecthed = Map.get(context, refetch_key(type))

    if module != nil && assocs != [] && refecthed != [] do
      Enum.reduce(refecthed, multi, fn resource, inner_multi ->
        fix_single_owner_references_multi(snapshot, context, type, resource, inner_multi)
      end)
    else
      multi
    end
  end

  defp fix_single_owner_references_multi(snapshot, context, type, resource, inner_multi) do
    from_snap =
      snapshot
      |> Map.get(type, [])
      |> Enum.find(fn m -> m.name == resource.name end)

    module = module_by_resouce_type(type)
    assocs = get_associations(module)

    # Add all the changes that we need to a map so that can be used to create a changeset
    updates =
      Enum.reduce(assocs, %{}, fn field, acc ->
        # For every association check if it is a belongs to
        # If it is then we need to find the new reference
        # and set it to the new ID
        # If it is not then we can just skip it
        case apply(module, :__schema__, [:association, field]) do
          %BelongsTo{owner_key: owner_field, related: related_module} ->
            related_id = Map.get(from_snap, owner_field)

            # We need the related type since that is the field in
            # containg possible referenced resources.
            related_type = type_by_module(related_module)

            ref_in_snap =
              snapshot
              |> Map.get(related_type, [])
              |> Enum.find(fn m -> m.id == related_id end)

            should_ref =
              context
              |> Map.get(refetch_key(related_type))
              |> Enum.find(fn m -> m.name == ref_in_snap.name end)

            Map.put(acc, owner_field, should_ref.id)

          _ ->
            acc
        end
      end)

    changeset = apply(module, :changeset, [resource, updates])

    Multi.update(inner_multi, fix_ref_key(type, resource), changeset)
  end

  def get_associations(nil), do: []

  def get_associations(module) do
    module
    |> apply(:__schema__, [:associations])
    |> Enum.filter(fn a -> a != :project end)
  end

  defp prepare_for_insert(module, attrs, project) do
    asocs = get_associations(module)

    left =
      attrs
      |> Map.from_struct()
      |> Map.delete(:id)
      |> Map.delete(:__meta__)

    # Nil out all the associations
    asocs
    |> Enum.reduce(left, fn field, acc ->
      case module.__schema__(:association, field) do
        %BelongsTo{owner_key: owner_field} ->
          Map.put(acc, owner_field, nil)

        _ ->
          acc
      end
    end)
    |> Map.put(:project_id, project.id)
  end

  defp module_by_resouce_type(:postgres_clusters), do: Cluster

  defp module_by_resouce_type(:redis_instances), do: RedisInstance

  defp module_by_resouce_type(:ferret_services), do: FerretService

  defp module_by_resouce_type(:jupyter_notebooks), do: JupyterLabNotebook

  defp module_by_resouce_type(:knative_services), do: Service

  defp module_by_resouce_type(:traditional_services), do: CommonCore.TraditionalServices.Service

  defp module_by_resouce_type(:model_instances), do: ModelInstance

  defp module_by_resouce_type(:ip_address_pools), do: IPAddressPool

  defp module_by_resouce_type(_), do: nil

  defp type_by_module(Cluster), do: :postgres_clusters

  defp type_by_module(RedisInstance), do: :redis_instances

  defp type_by_module(FerretService), do: :ferret_services

  defp type_by_module(JupyterLabNotebook), do: :jupyter_notebooks

  defp type_by_module(Service), do: :knative_services

  defp type_by_module(CommonCore.TraditionalServices.Service), do: :traditional_services

  defp type_by_module(ModelInstance), do: :model_instances

  defp type_by_module(IPAddressPool), do: :ip_address_pools

  defp type_by_module(_), do: nil

  defp refetch_key(type), do: "re_fetch_#{type}"
  defp fix_ref_key(type, resource), do: "fix_ref_#{type}_#{resource.name}"
end

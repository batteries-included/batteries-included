defmodule ControlServer.Deleted.DeleteArchivist do
  @moduledoc false

  use ControlServer, :context

  import K8s.Resource.FieldAccessors

  alias CommonCore.ApiVersionKind
  alias CommonCore.Resources.Hashing
  alias ControlServer.ContentAddressable
  alias ControlServer.ContentAddressable.Document
  alias ControlServer.Deleted.DeletedResource

  # Given a resource map, record its deletion in the DeletedResource table,
  # along with a content-addressable snapshot of the resource at deletion time.
  def record_delete(resource, repo \\ Repo) do
    resource
    |> delete_multi()
    |> repo.transaction()
  end

  def list_deleted_resources(params) do
    Repo.Flop.validate_and_run(DeletedResource, params, for: DeletedResource)
  end

  @doc """
  Gets a single DeletedResource.

  ## Examples

      iex> get_deleted_Resource!(123)
      %DeletedResource{}

      iex> get_deleted_resource!(456)
      ** (Ecto.NoResultsError)

  """
  def get_deleted_resource!(id, repo \\ Repo) do
    DeletedResource
    |> repo.get!(id)
    |> repo.preload([:document])
  end

  @doc """
  Updates a DeletedResource.

  ## Examples

      iex> update_deleted_resource(%{field: value})
      {:ok, %DeletedResource{}}

      iex> update_deleted_resource(%{field: bad_value})
      {:error, %Ecto.Chnageset{}}

  """
  def update_deleted_resource(%DeletedResource{} = deleted_resource, attrs, repo \\ Repo) do
    deleted_resource
    |> DeletedResource.changeset(attrs)
    |> repo.update()
  end

  defp delete_multi(resource) do
    hash = Hashing.compute_hash(resource)

    Multi.new()
    |> Multi.one(:selected_document, fn _ ->
      from Document, where: [hash: ^hash], select: [:id, :hash]
    end)
    |> Multi.run(:final_document, fn
      repo, %{:selected_document => nil} ->
        resource
        |> addressable_args(hash)
        |> ContentAddressable.create_document(repo)

      _, %{:selected_document => existing} ->
        {:ok, existing}
    end)
    |> Multi.insert(:deleted_resource, fn %{final_document: car} = _status ->
      deleted_resource_builder(resource, hash, car)
    end)
  end

  defp deleted_resource_builder(%{} = resource, hash, %Document{} = car) when is_binary(hash) do
    %DeletedResource{
      hash: hash,
      name: name(resource),
      namespace: namespace(resource),
      kind: ApiVersionKind.resource_type!(resource),
      document_id: Map.get(car, :id, nil),
      been_undeleted: false
    }
  end

  defp addressable_args(resource, hash) do
    id = Document.hash_to_uuid!(hash)

    %{
      value: resource,
      hash: hash,
      id: id
    }
  end
end

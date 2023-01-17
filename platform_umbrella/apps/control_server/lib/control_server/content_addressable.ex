defmodule ControlServer.ContentAddressable do
  import Ecto.Query, warn: false
  alias ControlServer.Repo

  alias ControlServer.ContentAddressable.ContentAddressableResource

  def list_content_addressable_resources do
    Repo.all(ContentAddressableResource)
  end

  def count_content_addressable_resources do
    Repo.aggregate(ContentAddressableResource, :count)
  end

  @doc """
  Creates a content_addressable_resource.

  ## Examples

      iex> create_content_addressable_resource(%{field: value})
      {:ok, %ContentAddressableResource{}}

      iex> create_content_addressable_resource(%{field: bad_value})
      {:error, ...}

  """
  def create_content_addressable_resource(attrs \\ %{}, repo \\ Repo) do
    %ContentAddressableResource{}
    |> ContentAddressableResource.changeset(attrs)
    |> repo.insert()
  end
end

defmodule ControlServer.ContentAddressable do
  @moduledoc false

  use ControlServer, :context

  alias ControlServer.ContentAddressable.Document

  def list_documents do
    Repo.all(Document)
  end

  def list_documents(params) do
    Repo.Flop.validate_and_run(Document, params, for: Document)
  end

  def count_documents do
    Repo.aggregate(Document, :count)
  end

  @doc """
  Creates a content_addressable_resource.

  ## Examples

      iex> create_document(%{field: value})
      {:ok, %Document{}}

      iex> create_document(%{field: bad_value})
      {:error, ...}

  """
  def create_document(attrs \\ %{}, repo \\ Repo) do
    %Document{}
    |> Document.changeset(attrs)
    |> repo.insert()
  end

  def get_stats(repo \\ Repo) do
    repo.one(
      from car in Document,
        select: %{
          oldest: min(car.inserted_at),
          newest: max(car.inserted_at),
          record_count: count(car.id)
        }
    )
  end
end

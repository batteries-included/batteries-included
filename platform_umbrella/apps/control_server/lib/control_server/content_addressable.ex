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

  def get_stats(repo \\ Repo) do
    repo.one(
      from car in ContentAddressableResource,
        select: %{
          oldest: min(car.inserted_at),
          newest: max(car.inserted_at),
          record_count: count(car.id)
        }
    )
  end

  def paginated_content_addressable_resources(opts \\ []) do
    default_opts = [
      include_total_count: true,
      cursor_fields: [{:inserted_at, :desc}, {:id, :desc}],
      limit: 12
    ]

    total_opts = Keyword.merge(default_opts, opts)

    Repo.paginate(
      from(car in ContentAddressableResource,
        order_by: [desc: car.inserted_at, desc: car.id]
      ),
      total_opts
    )
  end
end

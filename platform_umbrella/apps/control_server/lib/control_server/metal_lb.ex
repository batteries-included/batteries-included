defmodule ControlServer.MetalLB do
  @moduledoc false

  use ControlServer, :context

  alias CommonCore.MetalLB.IPAddressPool

  @doc """
  Returns the list of ip_address_pools.

  ## Examples

      iex> list_ip_address_pools()
      [%IPAddressPool{}, ...]

  """
  def list_ip_address_pools do
    Repo.all(IPAddressPool)
  end

  @doc """
  Gets a single ip_address_pool.

  Raises `Ecto.NoResultsError` if the Ip address pool does not exist.

  ## Examples

      iex> get_ip_address_pool!(123)
      %IPAddressPool{}

      iex> get_ip_address_pool!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ip_address_pool!(id), do: Repo.get!(IPAddressPool, id)

  @doc """
  Creates a ip_address_pool.

  ## Examples

      iex> create_ip_address_pool(%{field: value})
      {:ok, %IPAddressPool{}}

      iex> create_ip_address_pool(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ip_address_pool(attrs \\ %{}) do
    %IPAddressPool{}
    |> IPAddressPool.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ip_address_pool.

  ## Examples

      iex> update_ip_address_pool(ip_address_pool, %{field: new_value})
      {:ok, %IPAddressPool{}}

      iex> update_ip_address_pool(ip_address_pool, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ip_address_pool(%IPAddressPool{} = ip_address_pool, attrs) do
    ip_address_pool
    |> IPAddressPool.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ip_address_pool.

  ## Examples

      iex> delete_ip_address_pool(ip_address_pool)
      {:ok, %IPAddressPool{}}

      iex> delete_ip_address_pool(ip_address_pool)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ip_address_pool(%IPAddressPool{} = ip_address_pool) do
    Repo.delete(ip_address_pool)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ip_address_pool changes.

  ## Examples

      iex> change_ip_address_pool(ip_address_pool)
      %Ecto.Changeset{data: %IPAddressPool{}}

  """
  def change_ip_address_pool(%IPAddressPool{} = ip_address_pool, attrs \\ %{}) do
    IPAddressPool.changeset(ip_address_pool, attrs)
  end
end

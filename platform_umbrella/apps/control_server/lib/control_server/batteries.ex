defmodule ControlServer.Batteries do
  @moduledoc false

  use ControlServer, :context

  alias CommonCore.Batteries.SystemBattery
  alias EventCenter.Database, as: DatabaseEventCenter

  @doc """
  Returns the list of system_batteries.

  ## Examples

      iex> list_system_batteries()
      [%SystemBattery{}, ...]

  """
  @spec list_system_batteries() :: [SystemBattery.t()]
  def list_system_batteries do
    Repo.all(SystemBattery)
  end

  @spec list_system_batteries_slim() :: [SystemBattery.t()]
  def list_system_batteries_slim do
    from(sb in SystemBattery)
    |> select([:id, :group, :type, :inserted_at, :updated_at])
    |> order_by(desc: :updated_at)
    |> Repo.all()
  end

  def list_system_batteries_for_group(group, repo \\ Repo) do
    repo.all(from sb in SystemBattery, where: sb.group == ^group)
  end

  @doc """
  Gets a single system_battery.

  Raises `Ecto.NoResultsError` if the System battery does not exist.

  ## Examples

      iex> get_system_battery!(123)
      %SystemBattery{}

      iex> get_system_battery!(456)
      ** (Ecto.NoResultsError)

  """
  def get_system_battery!(id), do: Repo.get!(SystemBattery, id)

  def battery_enabled?(type) do
    query = from sb in SystemBattery, where: sb.type == ^type
    Repo.exists?(query)
  end

  @doc """
  Creates a system_battery.

  ## Examples

      iex> create_system_battery(%{field: value})
      {:ok, %SystemBattery{}}

      iex> create_system_battery(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_system_battery(attrs \\ %{}) do
    %SystemBattery{}
    |> SystemBattery.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:insert)
  end

  @doc """
  Updates a system_battery.

  ## Examples

      iex> update_system_battery(system_battery, %{field: new_value})
      {:ok, %SystemBattery{}}

      iex> update_system_battery(system_battery, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_system_battery(%SystemBattery{} = system_battery, attrs) do
    system_battery
    |> SystemBattery.changeset(attrs)
    |> Repo.update()
    |> broadcast(:update)
  end

  @doc """
  Deletes a system_battery.

  ## Examples

      iex> delete_system_battery(system_battery)
      {:ok, %SystemBattery{}}

      iex> delete_system_battery(system_battery)
      {:error, %Ecto.Changeset{}}

  """
  def delete_system_battery(%SystemBattery{} = system_battery) do
    system_battery
    |> Repo.delete()
    |> broadcast(:delete)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking system_battery changes.

  ## Examples

      iex> change_system_battery(system_battery)
      %Ecto.Changeset{data: %SystemBattery{}}

  """
  def change_system_battery(%SystemBattery{} = system_battery, attrs \\ %{}) do
    SystemBattery.changeset(system_battery, attrs)
  end

  defp broadcast({:ok, fc} = result, action) do
    :ok = DatabaseEventCenter.broadcast(:system_battery, action, fc)
    result
  end

  defp broadcast(result, _action), do: result
end

defmodule HomeBase.CustomerInstalls do
  @moduledoc false
  use HomeBase, :context

  alias CommonCore.Accounts.User
  alias CommonCore.Installation
  alias CommonCore.Teams.Team
  alias CommonCore.Teams.TeamRole

  @doc """
  Returns the list of installations.

  ## Examples

      iex> list_installations()
      [%Installation{}, ...]

  """
  def list_installations do
    Repo.all(Installation)
  end

  def list_installations(owner) do
    from(i in Installation)
    |> where_owner(owner)
    |> Repo.all()
  end

  def list_recent_installations(%User{} = user, limit \\ 8) do
    from(i in Installation, order_by: [desc: i.inserted_at], preload: [:team], limit: ^limit)
    |> where_user_has_access(user)
    |> Repo.all()
  end

  def count_installations(%User{} = user) do
    from(i in Installation)
    |> where_user_has_access(user)
    |> Repo.aggregate(:count)
  end

  def count_installations(owner) do
    from(i in Installation)
    |> where_owner(owner)
    |> Repo.aggregate(:count)
  end

  def count_teams(%User{} = user) do
    Repo.aggregate(from(tr in TeamRole, where: tr.user_id == ^user.id), :count)
  end

  @doc """
  Gets a single installation. This is not scoped to a
  user or team, you should use those functions instead unless it's
  in the admin context.

  Raises `Ecto.NoResultsError` if the Installation does not exist.

  ## Examples

      iex> get_installation!(123)
      %Installation{}

      iex> get_installation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_installation!(id) do
    Installation
    |> preload([:team, :user])
    |> Repo.get!(id)
  end

  def get_installation!(id, owner) do
    from(i in Installation, where: i.id == ^id)
    |> where_owner(owner)
    |> Repo.one!()
  end

  @spec get_installation(binary()) :: Ecto.Schema.t() | nil
  def get_installation(id) do
    Repo.get(Installation, id)
  end

  @spec create_installation(list() | map()) :: any()
  @doc """
  Creates a installation.

  ## Examples

      iex> create_installation(%{field: value})
      {:ok, %Installation{}}

      iex> create_installation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_installation(attrs \\ %{}) do
    %Installation{}
    |> Installation.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_installation(CommonCore.Installation.t(), any()) :: {:ok, CommonCore.Installation.t()} | {:error, any()}
  @doc """
  Updates a installation.

  ## Examples

      iex> update_installation(installation, %{field: new_value})
      {:ok, %Installation{}}

      iex> update_installation(installation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_installation(%Installation{} = installation, attrs) do
    installation
    |> Installation.changeset(attrs)
    |> Repo.update()
  end

  @spec remove_control_jwk(CommonCore.Installation.t()) ::
          {:ok, CommonCore.Installation.t()} | {:error, any()}
  def remove_control_jwk(%Installation{control_jwk: jwk} = installation) do
    update_installation(installation, %{control_jwk: CommonCore.JWK.public_key(jwk)})
  end

  @doc """
  Deletes a installation.

  ## Examples

      iex> delete_installation(installation)
      {:ok, %Installation{}}

      iex> delete_installation(installation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_installation(%Installation{} = installation) do
    Repo.soft_delete(installation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking installation changes.

  ## Examples

      iex> change_installation(installation)
      %Ecto.Changeset{data: %Installation{}}

  """
  def change_installation(%Installation{} = installation, attrs \\ %{}) do
    Installation.changeset(installation, attrs)
  end

  defp where_owner(query, owner) do
    case owner do
      %User{} = user -> where(query, [i], i.user_id == ^user.id)
      %Team{} = team -> where(query, [i], i.team_id == ^team.id)
      _ -> query
    end
  end

  # Installations where user either owns it or belongs to a team that owns it
  defp where_user_has_access(query, %User{} = user) do
    from(i in query,
      left_join: tr in TeamRole,
      on: i.team_id == tr.team_id,
      where: i.user_id == ^user.id or tr.user_id == ^user.id
    )
  end
end

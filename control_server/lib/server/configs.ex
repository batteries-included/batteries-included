defmodule Server.Configs do
  @moduledoc """
  The Configs context.
  """

  import Ecto.Query, warn: false
  alias Server.Repo

  alias Server.Configs.RawConfig

  @doc """
  Returns the list of raw_configs.

  ## Examples

      iex> list_raw_configs()
      [%RawConfig{}, ...]

  """
  def list_raw_configs do
    Repo.all(RawConfig)
  end

  @doc """
  Gets a single raw_config.

  Raises `Ecto.NoResultsError` if the Raw config does not exist.

  ## Examples

      iex> get_raw_config!(123)
      %RawConfig{}

      iex> get_raw_config!(456)
      ** (Ecto.NoResultsError)

  """
  def get_raw_config!(id), do: Repo.get!(RawConfig, id)

  @doc """
  Creates a raw_config.

  ## Examples

      iex> create_raw_config(%{field: value})
      {:ok, %RawConfig{}}

      iex> create_raw_config(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_raw_config(attrs \\ %{}) do
    %RawConfig{}
    |> RawConfig.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a raw_config.

  ## Examples

      iex> update_raw_config(raw_config, %{field: new_value})
      {:ok, %RawConfig{}}

      iex> update_raw_config(raw_config, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_raw_config(%RawConfig{} = raw_config, attrs) do
    raw_config
    |> RawConfig.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a raw_config.

  ## Examples

      iex> delete_raw_config(raw_config)
      {:ok, %RawConfig{}}

      iex> delete_raw_config(raw_config)
      {:error, %Ecto.Changeset{}}

  """
  def delete_raw_config(%RawConfig{} = raw_config) do
    Repo.delete(raw_config)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking raw_config changes.

  ## Examples

      iex> change_raw_config(raw_config)
      %Ecto.Changeset{data: %RawConfig{}}

  """
  def change_raw_config(%RawConfig{} = raw_config, attrs \\ %{}) do
    RawConfig.changeset(raw_config, attrs)
  end
end

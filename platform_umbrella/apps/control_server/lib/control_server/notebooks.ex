defmodule ControlServer.Notebooks do
  @moduledoc """
  The Notebooks context.
  """

  import Ecto.Query, warn: false

  alias CommonCore.Notebooks.JupyterLabNotebook
  alias ControlServer.Repo
  alias EventCenter.Database, as: DatabaseEventCenter

  @doc """
  Returns the list of jupyter_lab_notebooks.

  ## Examples

      iex> list_jupyter_lab_notebooks()
      [%JupyterLabNotebook{}, ...]

  """
  def list_jupyter_lab_notebooks do
    Repo.all(JupyterLabNotebook)
  end

  @doc """
  Gets a single jupyter_lab_notebook.

  Raises `Ecto.NoResultsError` if the Jupyter lab notebook does not exist.

  ## Examples

      iex> get_jupyter_lab_notebook!(123)
      %JupyterLabNotebook{}

      iex> get_jupyter_lab_notebook!(456)
      ** (Ecto.NoResultsError)

  """
  def get_jupyter_lab_notebook!(id), do: Repo.get!(JupyterLabNotebook, id)

  @doc """
  Creates a jupyter_lab_notebook.

  ## Examples

      iex> create_jupyter_lab_notebook(%{field: value})
      {:ok, %JupyterLabNotebook{}}

      iex> create_jupyter_lab_notebook(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_jupyter_lab_notebook(attrs \\ %{}) do
    %JupyterLabNotebook{}
    |> JupyterLabNotebook.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:insert)
  end

  @doc """
  Updates a jupyter_lab_notebook.

  ## Examples

      iex> update_jupyter_lab_notebook(jupyter_lab_notebook, %{field: new_value})
      {:ok, %JupyterLabNotebook{}}

      iex> update_jupyter_lab_notebook(jupyter_lab_notebook, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_jupyter_lab_notebook(%JupyterLabNotebook{} = jupyter_lab_notebook, attrs) do
    jupyter_lab_notebook
    |> JupyterLabNotebook.changeset(attrs)
    |> Repo.update()
    |> broadcast(:update)
  end

  @doc """
  Deletes a jupyter_lab_notebook.

  ## Examples

      iex> delete_jupyter_lab_notebook(jupyter_lab_notebook)
      {:ok, %JupyterLabNotebook{}}

      iex> delete_jupyter_lab_notebook(jupyter_lab_notebook)
      {:error, %Ecto.Changeset{}}

  """
  def delete_jupyter_lab_notebook(%JupyterLabNotebook{} = jupyter_lab_notebook) do
    jupyter_lab_notebook
    |> Repo.delete()
    |> broadcast(:delete)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking jupyter_lab_notebook changes.

  ## Examples

      iex> change_jupyter_lab_notebook(jupyter_lab_notebook)
      %Ecto.Changeset{data: %JupyterLabNotebook{}}

  """
  def change_jupyter_lab_notebook(%JupyterLabNotebook{} = jupyter_lab_notebook, attrs \\ %{}) do
    JupyterLabNotebook.changeset(jupyter_lab_notebook, attrs)
  end

  defp broadcast({:ok, fc} = result, action) do
    :ok = DatabaseEventCenter.broadcast(:jupyter_notebook, action, fc)
    result
  end

  defp broadcast(result, _action), do: result
end

defmodule HomeBaseWeb.StoredProjectSnapshotJSON do
  alias HomeBase.Projects.StoredProjectSnapshot

  @doc """
  Renders a single stored_project_snapshot.
  """
  def show(%{payload: payload}) do
    %{data: data(payload)}
  end

  @doc """
  Only the id is returned in the payload.
  """
  def data(%StoredProjectSnapshot{} = stored_project_snapshot) do
    %{id: stored_project_snapshot.id}
  end
end

defmodule HomeBaseWeb.StoredProjectSnapshotJSON do
  alias HomeBase.Projects.StoredProjectSnapshot

  @doc """
  Renders a single stored_project_snapshot.
  """
  def show(%{stored_project_snapshot: stored_project_snapshot}) do
    %{data: data(stored_project_snapshot)}
  end

  defp data(%StoredProjectSnapshot{} = stored_project_snapshot) do
    %{
      id: stored_project_snapshot.id
    }
  end
end

defmodule HomeBase.Projects do
  @moduledoc false
  import Ecto.Query, warn: false

  alias HomeBase.Projects.StoredProjectSnapshot
  alias HomeBase.Repo

  def create_stored_project_snapshot(attrs \\ %{}) do
    %StoredProjectSnapshot{}
    |> StoredProjectSnapshot.changeset(attrs)
    |> Repo.insert()
  end
end

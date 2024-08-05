defmodule ControlServer.Projects do
  @moduledoc false

  use ControlServer, :context

  alias CommonCore.Projects.Project

  def list_projects do
    Repo.all(Project)
  end

  def list_projects(params) do
    Repo.Flop.validate_and_run(Project, params, for: Project)
  end

  def get_project!(id) do
    Project
    |> preload(^Project.resource_types())
    |> Repo.get!(id)
  end

  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  def delete_project(%Project{} = project) do
    project
    |> Project.changeset(%{})
    |> Repo.delete()
  end

  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end
end

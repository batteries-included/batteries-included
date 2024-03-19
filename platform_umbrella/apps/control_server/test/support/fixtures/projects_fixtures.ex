defmodule ControlServer.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ControlServer.Projects` context.
  """

  @doc """
  Generate a project.
  """
  def project_fixture(attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
        name: "some name",
        type: :web,
        description: "some description"
      })
      |> ControlServer.Projects.create_project()

    project
  end
end

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
        description: "some description",
        name: "some name",
        type: :web
      })
      |> ControlServer.Projects.create_project()

    project
  end
end

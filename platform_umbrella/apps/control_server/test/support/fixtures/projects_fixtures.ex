defmodule ControlServer.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ControlServer.Projects` context.
  """

  @doc """
  Generate a system_project.
  """
  def system_project_fixture(attrs \\ %{}) do
    {:ok, system_project} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name",
        type: :web
      })
      |> ControlServer.Projects.create_system_project()

    system_project
  end
end

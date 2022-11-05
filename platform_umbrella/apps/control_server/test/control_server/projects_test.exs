defmodule ControlServer.ProjectsTest do
  use ControlServer.DataCase

  alias ControlServer.Projects

  describe "system_projects" do
    alias ControlServer.Projects.SystemProject

    import ControlServer.ProjectsFixtures

    @invalid_attrs %{description: nil, name: nil, type: nil}

    test "list_system_projects/0 returns all system_projects" do
      system_project = system_project_fixture()
      assert Projects.list_system_projects() == [system_project]
    end

    test "get_system_project!/1 returns the system_project with given id" do
      system_project = system_project_fixture()
      assert Projects.get_system_project!(system_project.id) == system_project
    end

    test "create_system_project/1 with valid data creates a system_project" do
      valid_attrs = %{description: "some description", name: "some name", type: :web}

      assert {:ok, %SystemProject{} = system_project} =
               Projects.create_system_project(valid_attrs)

      assert system_project.description == "some description"
      assert system_project.name == "some name"
      assert system_project.type == :web
    end

    test "create_system_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_system_project(@invalid_attrs)
    end

    test "update_system_project/2 with valid data updates the system_project" do
      system_project = system_project_fixture()

      update_attrs = %{
        description: "some updated description",
        name: "some updated name",
        type: :ml
      }

      assert {:ok, %SystemProject{} = system_project} =
               Projects.update_system_project(system_project, update_attrs)

      assert system_project.description == "some updated description"
      assert system_project.name == "some updated name"
      assert system_project.type == :ml
    end

    test "update_system_project/2 with invalid data returns error changeset" do
      system_project = system_project_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Projects.update_system_project(system_project, @invalid_attrs)

      assert system_project == Projects.get_system_project!(system_project.id)
    end

    test "delete_system_project/1 deletes the system_project" do
      system_project = system_project_fixture()
      assert {:ok, %SystemProject{}} = Projects.delete_system_project(system_project)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_system_project!(system_project.id) end
    end

    test "change_system_project/1 returns a system_project changeset" do
      system_project = system_project_fixture()
      assert %Ecto.Changeset{} = Projects.change_system_project(system_project)
    end
  end
end

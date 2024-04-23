defmodule ControlServer.ProjectsTest do
  use ControlServer.DataCase

  import ControlServer.Projects
  import ControlServer.ProjectsFixtures

  alias CommonCore.Projects.Project

  @valid_attrs %{name: "some name", type: :web, description: "some description"}
  @update_attrs %{name: "some updated name", type: :ai, description: "some updated description"}
  @invalid_attrs %{name: nil, type: nil, description: nil}

  setup do
    %{
      project: project_fixture(),
      project2: project_fixture(),
      project3: project_fixture()
    }
  end

  describe "list_projects/0" do
    test "should list all projects", ctx do
      assert list_projects() == [ctx.project, ctx.project2, ctx.project3]
    end
  end

  describe "get_project!/1" do
    test "should return the project with given id", ctx do
      assert get_project!(ctx.project.id) == ctx.project
    end
  end

  describe "create_project/1" do
    test "should create project with valid data" do
      assert {:ok, %Project{} = project} = create_project(@valid_attrs)
      assert project.description == "some description"
      assert project.name == "some name"
      assert project.type == :web
    end

    test "should return error changeset with invalid data" do
      assert {:error, %Ecto.Changeset{}} = create_project(@invalid_attrs)
    end
  end

  describe "update_project/2" do
    test "should update the project with valid data", ctx do
      assert {:ok, %Project{} = project} = update_project(ctx.project, @update_attrs)
      assert project.description == "some updated description"
      assert project.name == "some updated name"
      assert project.type == :ai
    end

    test "should return error changeset with invalid data", ctx do
      assert {:error, %Ecto.Changeset{}} = update_project(ctx.project, @invalid_attrs)
      assert ctx.project == get_project!(ctx.project.id)
    end
  end

  describe "delete_project/1" do
    test "should delete the project", ctx do
      assert {:ok, %Project{}} = delete_project(ctx.project)
      assert_raise Ecto.NoResultsError, fn -> get_project!(ctx.project.id) end
    end
  end

  describe "change_project/1" do
    test "should return a project changeset", ctx do
      assert %Ecto.Changeset{} = change_project(ctx.project)
    end
  end
end

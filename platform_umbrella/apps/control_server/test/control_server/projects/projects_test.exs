defmodule ControlServer.ProjectsTest do
  use ControlServer.DataCase

  import ControlServer.Factory
  import ControlServer.Notebooks
  import ControlServer.Projects
  import ControlServer.ProjectsFixtures

  alias CommonCore.Projects.Project

  @valid_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
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

  describe "list_projects/1" do
    test "should list paginated projects", ctx do
      assert {:ok, {[project], _}} = list_projects(%{limit: 1})
      assert project == ctx.project
    end
  end

  describe "get_project!/1" do
    test "should return the project with given id", ctx do
      assert get_project!(ctx.project.id).name == ctx.project.name
    end
  end

  describe "create_project/1" do
    test "should create project with valid data" do
      assert {:ok, %Project{} = project} = create_project(@valid_attrs)
      assert project.description == "some description"
      assert project.name == "some name"
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
    end

    test "should return error changeset with invalid data", %{project: project} = ctx do
      assert {:error, %Ecto.Changeset{}} = update_project(project, @invalid_attrs)
      assert ctx.project.name == get_project!(project.id).name
    end
  end

  describe "delete_project/1" do
    test "should delete the project", ctx do
      assert {:ok, %Project{}} = delete_project(ctx.project)
      assert_raise Ecto.NoResultsError, fn -> get_project!(ctx.project.id) end
    end

    test "should not return error while project still has resources", ctx do
      notebook = insert(:jupyter_lab_notebook, project_id: ctx.project.id)

      assert {:ok, %Project{}} = delete_project(ctx.project)
      refute get_jupyter_lab_notebook!(notebook.id).project_id
    end
  end

  describe "change_project/1" do
    test "should return a project changeset", ctx do
      assert %Ecto.Changeset{} = change_project(ctx.project)
    end
  end
end

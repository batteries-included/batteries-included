defmodule ControlServer.NotebooksTest do
  use ControlServer.DataCase

  alias ControlServer.Notebooks
  alias CommonCore.Notebooks.JupyterLabNotebook

  describe "jupyter_lab_notebooks" do
    @valid_attrs %{image: "some image", name: "some name"}
    @update_attrs %{image: "some updated image", name: "some updated name"}
    @invalid_attrs %{image: nil, name: nil}

    def jupyter_lab_notebook_fixture(attrs \\ %{}) do
      {:ok, jupyter_lab_notebook} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Notebooks.create_jupyter_lab_notebook()

      jupyter_lab_notebook
    end

    test "list_jupyter_lab_notebooks/0 returns all jupyter_lab_notebooks" do
      jupyter_lab_notebook = jupyter_lab_notebook_fixture()
      assert Notebooks.list_jupyter_lab_notebooks() == [jupyter_lab_notebook]
    end

    test "get_jupyter_lab_notebook!/1 returns the jupyter_lab_notebook with given id" do
      jupyter_lab_notebook = jupyter_lab_notebook_fixture()
      assert Notebooks.get_jupyter_lab_notebook!(jupyter_lab_notebook.id) == jupyter_lab_notebook
    end

    test "create_jupyter_lab_notebook/1 with valid data creates a jupyter_lab_notebook" do
      assert {:ok, %JupyterLabNotebook{} = jupyter_lab_notebook} =
               Notebooks.create_jupyter_lab_notebook(@valid_attrs)

      assert jupyter_lab_notebook.image == "some image"
      assert jupyter_lab_notebook.name == "some name"
    end

    test "create_jupyter_lab_notebook/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notebooks.create_jupyter_lab_notebook(@invalid_attrs)
    end

    test "update_jupyter_lab_notebook/2 with valid data updates the jupyter_lab_notebook" do
      jupyter_lab_notebook = jupyter_lab_notebook_fixture()

      assert {:ok, %JupyterLabNotebook{} = jupyter_lab_notebook} =
               Notebooks.update_jupyter_lab_notebook(jupyter_lab_notebook, @update_attrs)

      assert jupyter_lab_notebook.image == "some updated image"
      assert jupyter_lab_notebook.name == "some updated name"
    end

    test "update_jupyter_lab_notebook/2 with invalid data returns error changeset" do
      jupyter_lab_notebook = jupyter_lab_notebook_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Notebooks.update_jupyter_lab_notebook(jupyter_lab_notebook, @invalid_attrs)

      assert jupyter_lab_notebook == Notebooks.get_jupyter_lab_notebook!(jupyter_lab_notebook.id)
    end

    test "delete_jupyter_lab_notebook/1 deletes the jupyter_lab_notebook" do
      jupyter_lab_notebook = jupyter_lab_notebook_fixture()

      assert {:ok, %JupyterLabNotebook{}} =
               Notebooks.delete_jupyter_lab_notebook(jupyter_lab_notebook)

      assert_raise Ecto.NoResultsError, fn ->
        Notebooks.get_jupyter_lab_notebook!(jupyter_lab_notebook.id)
      end
    end

    test "change_jupyter_lab_notebook/1 returns a jupyter_lab_notebook changeset" do
      jupyter_lab_notebook = jupyter_lab_notebook_fixture()
      assert %Ecto.Changeset{} = Notebooks.change_jupyter_lab_notebook(jupyter_lab_notebook)
    end
  end
end

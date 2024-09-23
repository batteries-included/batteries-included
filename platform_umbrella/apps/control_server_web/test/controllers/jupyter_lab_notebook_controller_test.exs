defmodule ControlServerWeb.JupyterLabNotebookControllerTest do
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  alias CommonCore.Notebooks.JupyterLabNotebook

  @invalid_attrs %{name: nil, image: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all jupyter_lab_notebooks", %{conn: conn} do
      conn = get(conn, ~p"/api/notebooks/jupyter_lab_notebooks")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create jupyter_lab_notebook" do
    test "renders jupyter_lab_notebook when data is valid", %{conn: conn} do
      create_attrs = params_for(:jupyter_lab_notebook, name: "some-name")
      conn = post(conn, ~p"/api/notebooks/jupyter_lab_notebooks", jupyter_lab_notebook: create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/notebooks/jupyter_lab_notebooks/#{id}")

      assert %{
               "id" => ^id,
               "image" => _,
               "name" => "some-name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/notebooks/jupyter_lab_notebooks", jupyter_lab_notebook: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update jupyter_lab_notebook" do
    setup [:create_jupyter_lab_notebook]

    test "renders jupyter_lab_notebook when data is valid", %{
      conn: conn,
      jupyter_lab_notebook: %JupyterLabNotebook{id: id} = jupyter_lab_notebook
    } do
      update_attrs =
        params_for(:jupyter_lab_notebook, image: "some-updated-image:latest", name: jupyter_lab_notebook.name)

      conn =
        put(conn, ~p"/api/notebooks/jupyter_lab_notebooks/#{jupyter_lab_notebook}", jupyter_lab_notebook: update_attrs)

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/notebooks/jupyter_lab_notebooks/#{id}")

      assert %{
               "id" => ^id,
               "image" => "some-updated-image:latest"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, jupyter_lab_notebook: jupyter_lab_notebook} do
      conn =
        put(conn, ~p"/api/notebooks/jupyter_lab_notebooks/#{jupyter_lab_notebook}", jupyter_lab_notebook: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete jupyter_lab_notebook" do
    setup [:create_jupyter_lab_notebook]

    test "deletes chosen jupyter_lab_notebook", %{conn: conn, jupyter_lab_notebook: jupyter_lab_notebook} do
      conn = delete(conn, ~p"/api/notebooks/jupyter_lab_notebooks/#{jupyter_lab_notebook}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/notebooks/jupyter_lab_notebooks/#{jupyter_lab_notebook}")
      end
    end
  end

  defp create_jupyter_lab_notebook(_) do
    jupyter_lab_notebook = insert(:jupyter_lab_notebook)
    %{jupyter_lab_notebook: jupyter_lab_notebook}
  end
end

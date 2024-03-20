defmodule ControlServerWeb.JupyterLabNotebookController do
  use ControlServerWeb, :controller

  alias CommonCore.Notebooks.JupyterLabNotebook
  alias ControlServer.Notebooks

  action_fallback ControlServerWeb.FallbackController

  def index(conn, _params) do
    jupyter_lab_notebooks = Notebooks.list_jupyter_lab_notebooks()
    render(conn, :index, jupyter_lab_notebooks: jupyter_lab_notebooks)
  end

  def create(conn, %{"jupyter_lab_notebook" => jupyter_lab_notebook_params}) do
    with {:ok, %JupyterLabNotebook{} = jupyter_lab_notebook} <-
           Notebooks.create_jupyter_lab_notebook(jupyter_lab_notebook_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/notebooks/jupyter_lab_notebooks/#{jupyter_lab_notebook}")
      |> render(:show, jupyter_lab_notebook: jupyter_lab_notebook)
    end
  end

  def show(conn, %{"id" => id}) do
    jupyter_lab_notebook = Notebooks.get_jupyter_lab_notebook!(id)
    render(conn, :show, jupyter_lab_notebook: jupyter_lab_notebook)
  end

  def update(conn, %{"id" => id, "jupyter_lab_notebook" => jupyter_lab_notebook_params}) do
    jupyter_lab_notebook = Notebooks.get_jupyter_lab_notebook!(id)

    with {:ok, %JupyterLabNotebook{} = jupyter_lab_notebook} <-
           Notebooks.update_jupyter_lab_notebook(jupyter_lab_notebook, jupyter_lab_notebook_params) do
      render(conn, :show, jupyter_lab_notebook: jupyter_lab_notebook)
    end
  end

  def delete(conn, %{"id" => id}) do
    jupyter_lab_notebook = Notebooks.get_jupyter_lab_notebook!(id)

    with {:ok, %JupyterLabNotebook{}} <- Notebooks.delete_jupyter_lab_notebook(jupyter_lab_notebook) do
      send_resp(conn, :no_content, "")
    end
  end
end

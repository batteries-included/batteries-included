defmodule ControlServerWeb.JupyterLabNotebookJSON do
  alias CommonCore.Notebooks.JupyterLabNotebook

  @doc """
  Renders a list of jupyter_lab_notebooks.
  """
  def index(%{jupyter_lab_notebooks: jupyter_lab_notebooks}) do
    %{data: for(jupyter_lab_notebook <- jupyter_lab_notebooks, do: data(jupyter_lab_notebook))}
  end

  @doc """
  Renders a single jupyter_lab_notebook.
  """
  def show(%{jupyter_lab_notebook: jupyter_lab_notebook}) do
    %{data: data(jupyter_lab_notebook)}
  end

  defp data(%JupyterLabNotebook{} = jupyter_lab_notebook) do
    %{
      id: jupyter_lab_notebook.id,
      image: jupyter_lab_notebook.image,
      name: jupyter_lab_notebook.name
    }
  end
end

defmodule ControlServerWeb.Live.JupyterLabNotebookEdit do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Notebooks
  alias ControlServerWeb.Live.Notebooks.FormComponent

  def mount(%{"id" => id}, _session, socket) do
    notebook = Notebooks.get_jupyter_lab_notebook!(id)

    {:ok,
     socket
     |> assign(:current_page, :ai)
     |> assign(:page_title, "Edit Jupyter Notebook")
     |> assign(:notebook, notebook)}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={FormComponent}
      notebook={@notebook}
      id="notebook-form"
      action={:edit}
      title="Edit Jupyter Notebook"
    />
    """
  end
end

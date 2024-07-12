defmodule ControlServerWeb.Live.JupyterLabNotebookIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.NotebooksTable

  alias ControlServer.Notebooks

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_page_title()
     |> assign_notebooks()
     |> assign_current_page()}
  end

  defp assign_page_title(socket) do
    assign(socket, :page_title, "Jupyter Notebooks")
  end

  defp assign_notebooks(socket) do
    assign(socket, :notebooks, Notebooks.list_jupyter_lab_notebooks())
  end

  defp assign_current_page(socket) do
    assign(socket, :current_page, :ai)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/ai"}>
      <.button variant="dark" icon={:plus} link={~p"/notebooks/new"}>
        New Notebook
      </.button>
    </.page_header>

    <.panel title="All Notebooks">
      <.notebooks_table rows={@notebooks} />
    </.panel>
    """
  end
end

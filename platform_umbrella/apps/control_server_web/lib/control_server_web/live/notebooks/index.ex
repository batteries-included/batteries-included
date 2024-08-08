defmodule ControlServerWeb.Live.JupyterLabNotebookIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.NotebooksTable

  alias ControlServer.Notebooks

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, :ai)
     |> assign(:page_title, "Jupyter Notebooks")}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    with {:ok, {notebooks, meta}} <- Notebooks.list_jupyter_lab_notebooks(params) do
      {:noreply,
       socket
       |> assign(:meta, meta)
       |> assign(:notebooks, notebooks)
       |> assign(:form, to_form(meta))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("search", params, socket) do
    params = Map.delete(params, "_target")
    {:noreply, push_patch(socket, to: ~p"/notebooks?#{params}")}
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
      <:menu>
        <.table_search
          meta={@meta}
          fields={[name: [op: :ilike]]}
          placeholder="Filter by name"
          on_change="search"
        />
      </:menu>

      <.notebooks_table rows={@notebooks} meta={@meta} />
    </.panel>
    """
  end
end

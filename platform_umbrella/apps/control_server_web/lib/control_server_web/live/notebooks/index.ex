defmodule ControlServerWeb.Live.JupyterLabNotebookIndex do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServer.Notebooks
  import ControlServerWeb.NotebooksTable

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_page_title()
     |> assign_notebooks()
     |> assign_current_page()}
  end

  defp assign_page_title(socket) do
    assign(socket, :page_title, "AI Notebooks")
  end

  defp assign_notebooks(socket) do
    assign(socket, :notebooks, list_jupyter_lab_notebooks())
  end

  defp assign_current_page(socket) do
    assign(socket, :current_page, :ai)
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete_notebook", %{"id" => id}, socket) do
    {:ok, _} = id |> get_jupyter_lab_notebook!() |> delete_jupyter_lab_notebook()

    {:noreply, assign_notebooks(socket)}
  end

  def handle_event("start_notebook", _, socket) do
    with {:ok, _} <- create_jupyter_lab_notebook(KubeServices.SmartBuilder.new_juptyer_params()) do
      {:noreply, assign_notebooks(socket)}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/ai"} />
    <.panel title="Jupyter Notebooks">
      <:menu>
        <.button variant="primary" phx-click="start_notebook">
          Start New Notebook
        </.button>
      </:menu>
      <.notebooks_table rows={@notebooks} />
    </.panel>
    """
  end
end

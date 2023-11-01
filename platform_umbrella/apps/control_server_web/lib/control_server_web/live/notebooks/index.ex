defmodule ControlServerWeb.Live.JupyterLabNotebookIndex do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServer.Notebooks
  import ControlServerWeb.NotebooksTable

  alias ControlServer.Batteries.Installer

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket |> assign_page_title() |> assign_notebooks()}
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
    with {:ok, _} <- create_jupyter_lab_notebook(%{}) do
      Installer.install!(:notebooks)
      {:noreply, assign_notebooks(socket)}
    end
  end

  defp assign_page_title(socket) do
    assign(socket, :page_title, "ML Notebooks")
  end

  defp assign_notebooks(socket) do
    assign(socket, :notebooks, list_jupyter_lab_notebooks())
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_button={%{link_type: "live_redirect", to: "/ml"}} />
    <.panel title="Jupyter Notebooks">
      <:top_right>
        <.button type="primary" phx-click="start_notebook">
          Start New Notebook
        </.button>
      </:top_right>
      <.notebooks_table rows={@notebooks} />
    </.panel>
    """
  end
end

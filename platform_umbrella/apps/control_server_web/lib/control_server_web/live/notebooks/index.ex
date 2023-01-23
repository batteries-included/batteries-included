defmodule ControlServerWeb.Live.JupyterLabNotebookIndex do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.NotebooksTable

  alias ControlServer.Notebooks
  alias ControlServer.Batteries.Installer

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :notebooks, notebooks())}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete_notebook", %{"id" => id}, socket) do
    jupyter_lab_notebook = Notebooks.get_jupyter_lab_notebook!(id)
    {:ok, _} = Notebooks.delete_jupyter_lab_notebook(jupyter_lab_notebook)

    {:noreply, assign(socket, :notebooks, notebooks())}
  end

  def handle_event("start_notebook", _, socket) do
    with {:ok, _} <-
           Notebooks.create_jupyter_lab_notebook(%{}) do
      Installer.install!(:notebooks)
      {:noreply, assign(socket, :notebooks, notebooks())}
    end
  end

  defp notebooks do
    Notebooks.list_jupyter_lab_notebooks()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.layout group={:ml} active={:notebooks}>
      <:title>
        <.title>Notebooks</.title>
      </:title>
      <.notebooks_table notebooks={@notebooks} />
      <.h2 variant="fancy">Actions</.h2>
      <.body_section>
        <.button type="primary" phx-click="start_notebook">
          Start New Notebook
        </.button>
      </.body_section>
    </.layout>
    """
  end
end

defmodule ControlServerWeb.Live.JupyterLabNotebook.Index do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.Live.JupyterLabNotebook.Display

  alias ControlServer.Notebooks
  alias ControlServer.Services.RunnableService

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :notebooks, notebooks())}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_notebook", %{"id" => id}, socket) do
    jupyter_lab_notebook = Notebooks.get_jupyter_lab_notebook!(id)
    {:ok, _} = Notebooks.delete_jupyter_lab_notebook(jupyter_lab_notebook)

    {:noreply, assign(socket, :notebooks, notebooks())}
  end

  def handle_event("start_notebook", _, socket) do
    with {:ok, _} <-
           Notebooks.create_jupyter_lab_notebook(%{}) do
      RunnableService.activate!(:notebooks)
      {:noreply, assign(socket, :notebooks, notebooks())}
    end
  end

  defp notebooks do
    Notebooks.list_jupyter_lab_notebooks()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Notebooks</.title>
      </:title>
      <:left_menu>
        <.ml_menu active="notebooks" />
      </:left_menu>
      <.body_section>
        <.notebook_display notebooks={@notebooks} />
      </.body_section>
    </.layout>
    """
  end
end

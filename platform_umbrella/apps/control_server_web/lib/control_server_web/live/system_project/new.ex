defmodule ControlServerWeb.Live.SystemProjectNew do
  use ControlServerWeb, :live_view

  import ControlServerWeb.MenuLayout

  alias ControlServer.Projects
  alias ControlServerWeb.Live.Project.FormComponent

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :system_project, %Projects.SystemProject{})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.menu_layout>
      <:title>
        <.title>New Project</.title>
      </:title>
      <div>
        <.live_component
          module={FormComponent}
          system_project={@system_project}
          id="new-project-form"
          action={:new}
          save_target={self()}
        />
      </div>
    </.menu_layout>
    """
  end
end

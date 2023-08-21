defmodule ControlServerWeb.Live.SystemProjectEdit do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

  alias ControlServer.Projects
  alias ControlServerWeb.Live.Project.FormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply, assign(socket, :system_project, Projects.get_system_project!(id))}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={FormComponent}
        system_project={@system_project}
        id={@system_project.id || "edit-project-form"}
        action={:edit}
        save_target={self()}
      />
    </div>
    """
  end
end

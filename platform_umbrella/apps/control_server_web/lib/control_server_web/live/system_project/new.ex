defmodule ControlServerWeb.Live.SystemProjectNew do
  use ControlServerWeb, {:live_view, layout: :fresh}

  alias ControlServer.Projects
  alias ControlServerWeb.Live.Project.FormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :system_project, %Projects.SystemProject{})}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={FormComponent}
        system_project={@system_project}
        id="new-project-form"
        action={:new}
        save_target={self()}
      />
    </div>
    """
  end
end

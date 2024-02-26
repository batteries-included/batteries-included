defmodule ControlServerWeb.Live.SystemProjectNew do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Projects
  alias ControlServerWeb.Live.Project.FormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Start Your Project")
     |> assign(:system_project, %Projects.SystemProject{})}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.page_header
        title={@page_title}
        back_button={%{link_type: "live_redirect", to: ~p"/system_projects"}}
      />

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

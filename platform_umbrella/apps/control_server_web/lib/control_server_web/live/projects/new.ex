defmodule ControlServerWeb.Projects.NewLive do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Projects
  alias ControlServerWeb.Projects.FormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Start Your Project")
     |> assign(:project, %Projects.Project{})}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.page_header title={@page_title} back_link={~p"/projects"} />

      <.live_component
        module={FormComponent}
        project={@project}
        id="new-project-form"
        action={:new}
        save_target={self()}
      />
    </div>
    """
  end
end

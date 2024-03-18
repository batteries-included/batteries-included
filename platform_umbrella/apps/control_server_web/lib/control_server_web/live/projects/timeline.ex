defmodule ControlServerWeb.Projects.TimelineLive do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Projects

  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Project Timeline")
     |> assign(:project, Projects.get_project!(id))}
  end

  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/projects/#{@project.id}"} />
    """
  end
end

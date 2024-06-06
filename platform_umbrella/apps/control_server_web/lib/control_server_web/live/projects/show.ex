defmodule ControlServerWeb.Projects.ShowLive do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors, only: [labeled_owner: 1]
  import ControlServerWeb.PodsTable
  import ControlServerWeb.PostgresClusterTable
  import ControlServerWeb.RedisTable

  alias ControlServer.Projects
  alias KubeServices.KubeState

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Project Details")
     |> assign_project(id)
     |> assign_pods()}
  end

  defp assign_project(socket, id) do
    assign(socket, project: Projects.get_project!(id))
  end

  defp assign_pods(%{assigns: %{project: project}} = socket) do
    knative_ids = Enum.map(project.knative_services, & &1.id)
    postgres_ids = Enum.map(project.postgres_clusters, & &1.id)
    redis_ids = Enum.map(project.redis_clusters, & &1.id)

    allowed_ids = MapSet.new(knative_ids ++ postgres_ids ++ redis_ids)
    pods = Enum.filter(KubeState.get_all(:pod), fn pod -> MapSet.member?(allowed_ids, labeled_owner(pod)) end)

    assign(socket, pods: pods)
  end

  def handle_event("delete", _params, socket) do
    case Projects.delete_project(socket.assigns.project) do
      {:ok, _} ->
        {:noreply, push_navigate(socket, to: ~p"/projects")}

      {:error, _changeset} ->
        # TODO: Either show a more detailed error message, or maybe just
        # nullify the project_id in each resource after showing a warning
        {:noreply, put_flash(socket, :global_error, "Project still has resources")}
    end
  end

  def render(assigns) do
    ~H"""
    <.page_header title={@page_title <> ": " <> @project.name} back_link={~p"/projects"}>
      <.flex class="items-center">
        <.button variant="dark" icon={:clock} link={~p"/projects/#{@project.id}/timeline"}>
          Project Timeline
        </.button>
      </.flex>
    </.page_header>

    <.flex column>
      <.panel :if={@project.description} title="Project Description">
        <%= @project.description %>
      </.panel>

      <.panel :if={@project.postgres_clusters != []} variant="gray" title="Postgres">
        <.postgres_clusters_table rows={@project.postgres_clusters} />
      </.panel>

      <.panel :if={@project.redis_clusters != []} variant="gray" title="Redis">
        <.redis_table rows={@project.redis_clusters} />
      </.panel>

      <.panel title="Pods" class="col-span-2">
        <.pods_table pods={@pods} />
      </.panel>
    </.flex>
    """
  end
end

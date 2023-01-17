defmodule ControlServerWeb.Live.DeletedResourcesIndex do
  use ControlServerWeb, :live_view
  import ControlServerWeb.LeftMenuLayout

  alias ControlServer.Stale.DeleteArchivist
  alias KubeServices.ResourceDeleter

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.layout group={:magic} active={:deleted}>
      <:title>
        <.title><%= @page_title %></.title>
      </:title>
      <.table id="deleted-resources-table" rows={@deleted_resources}>
        <:col :let={resource} label="Kind">
          <%= resource.kind %>
        </:col>
        <:col :let={resource} label="Name">
          <%= resource.name %>
        </:col>
        <:col :let={resource} label="Namespace">
          <%= resource.namespace %>
        </:col>
        <:col :let={resource} label="When">
          <%= Timex.from_now(resource.inserted_at) %>
        </:col>
        <:action :let={resource}>
          <.link
            :if={!resource.been_undeleted}
            phx-click="undelete"
            phx-value-id={resource.id}
            data-confirm="Are you sure?"
            variant="styled"
          >
            Un-Delete
          </.link>
        </:action>
      </.table>
    </.layout>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> assign_page_title("Deleted Resources")
     |> assign_deleted_resources(DeleteArchivist.list_deleted_resources())}
  end

  def assign_deleted_resources(socket, deleted_resources) do
    assign(socket, deleted_resources: deleted_resources)
  end

  def assign_page_title(socket, page_title) do
    assign(socket, page_title: page_title)
  end

  @impl Phoenix.LiveView
  def handle_event("undelete", %{"id" => id} = _params, socket) do
    ResourceDeleter.undelete(id)
    {:noreply, socket}
  end
end

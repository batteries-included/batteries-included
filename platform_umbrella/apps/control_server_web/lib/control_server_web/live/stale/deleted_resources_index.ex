defmodule ControlServerWeb.Live.DeletedResourcesIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Deleted.DeleteArchivist
  alias KubeServices.ResourceDeleter

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

  defp empty_state(assigns) do
    ~H"""
    <.panel title="Empty Delete Archive">
      <div class="max-w-none prose prose-lg dark:prose-invert my-4">
        <p>
          There no deleted resources. If the Batteries Included platform does delete any resources it will
          record that here. Deletes usually come from stale resources that are no longer referenced in
          deploys, or UI interaction on Kubernetes pages.
        </p>
      </div>
      <img class="w-auto max-w-md mx-auto" src={~p"/images/server-amico.svg"} alt="" />
    </.panel>
    """
  end

  defp deleted_resources_table(assigns) do
    ~H"""
    <.panel>
      <.table id="deleted-resources-table" rows={@rows}>
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
          <%= CommonCore.Util.Time.from_now(resource.inserted_at) %>
        </:col>
        <:col :let={resource} label="Restore">
          <.button
            :if={!resource.been_undeleted}
            variant="minimal"
            icon={:archive_box}
            phx-click="undelete"
            phx-value-id={resource.id}
            data-confirm="Are you sure?"
            id={"unkdelete-#{resource.id}"}
          />

          <.tooltip target_id={"unkdelete-#{resource.id}"}>
            Restore this resource
          </.tooltip>
        </:col>
      </.table>
    </.panel>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/magic"} />

    <.deleted_resources_table
      :if={@deleted_resources != nil && @deleted_resources != []}
      rows={@deleted_resources}
    />
    <.empty_state
      :if={@deleted_resources == nil || @deleted_resources == []}
      rows={@deleted_resources}
    />
    """
  end
end

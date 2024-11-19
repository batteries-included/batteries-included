defmodule ControlServerWeb.Live.DeletedResourcesIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Deleted.DeleteArchivist
  alias KubeServices.ResourceDeleter

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Deleted Resources")}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    with {:ok, {deleted_resources, meta}} <- DeleteArchivist.list_deleted_resources(params) do
      {:noreply,
       socket
       |> assign(:meta, meta)
       |> assign(:deleted_resources, deleted_resources)
       |> assign(:form, to_form(meta))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("search", params, socket) do
    params = Map.delete(params, "_target")
    {:noreply, push_patch(socket, to: ~p"/deleted_resources?#{params}")}
  end

  @impl Phoenix.LiveView
  def handle_event("undelete", %{"id" => id} = _params, socket) do
    ResourceDeleter.undelete(id)
    {:noreply, socket}
  end

  defp empty_state(assigns) do
    ~H"""
    <.panel title="Empty Delete Archive" id="empty-state-deleted">
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
      <:menu>
        <.table_search
          meta={@meta}
          fields={[name: [op: :ilike]]}
          placeholder="Filter by name"
          on_change="search"
        />
      </:menu>

      <.table
        id="deleted-resources-table"
        variant="paginated"
        rows={@rows}
        meta={@meta}
        path={~p"/deleted_resources"}
      >
        <:col :let={resource} field={:kind} label="Kind">
          <%= resource.kind %>
        </:col>
        <:col :let={resource} field={:name} label="Name">
          <%= resource.name %>
        </:col>
        <:col :let={resource} field={:namespace} label="Namespace">
          <%= resource.namespace %>
        </:col>
        <:col :let={resource} field={:kind} label="When">
          <%= CommonCore.Util.Time.from_now(resource.inserted_at) %>
        </:col>
        <:col :let={resource} label="Restore" field={nil}>
          <.button
            :if={!resource.been_undeleted}
            variant="minimal"
            icon={:archive_box}
            phx-click="undelete"
            phx-value-id={resource.id}
            data-confirm="Are you sure?"
            id={"undelete-#{resource.id}"}
          />

          <.tooltip target_id={"undelete-#{resource.id}"}>
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
      meta={@meta}
      rows={@deleted_resources}
    />
    <.empty_state
      :if={@deleted_resources == nil || @deleted_resources == []}
      rows={@deleted_resources}
    />
    """
  end
end

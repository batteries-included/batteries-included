defmodule ControlServerWeb.Live.FerretServiceShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.Audit.EditVersionsTable
  import ControlServerWeb.PodsTable

  alias CommonCore.Util.Memory
  alias ControlServer.FerretDB
  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState
  alias KubeServices.SystemState.SummaryBatteries

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :ok = KubeEventCenter.subscribe(:pod)
    end

    {:ok, assign_page_title(socket)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    service = FerretDB.get_ferret_service!(id, preload: [:project])

    {:noreply,
     socket
     |> assign_page_title()
     |> assign_current_page()
     |> assign_ferret_service(service)
     |> assign_pods()
     |> assign_timeline_installed()
     |> maybe_assign_edit_versions()}
  end

  defp assign_timeline_installed(socket) do
    assign(socket, :timeline_installed, SummaryBatteries.battery_installed(:timeline))
  end

  defp assign_current_page(socket) do
    assign(socket, current_page: :data)
  end

  defp assign_page_title(%{assigns: %{live_action: :show}} = socket) do
    assign(socket, page_title: "Show FerretDB Service")
  end

  defp assign_page_title(%{assigns: %{live_action: :edit_versions}} = socket) do
    assign(socket, page_title: "Ferret Service: Edit History")
  end

  defp assign_pods(%{assigns: %{ferret_service: ferret_service}} = socket) do
    pods =
      :pod
      |> KubeState.get_all()
      |> Enum.filter(fn pod -> ferret_service.id == labeled_owner(pod) end)

    assign(socket, pods: pods)
  end

  defp assign_ferret_service(socket, ferret_service) do
    assign(socket, ferret_service: ferret_service)
  end

  defp maybe_assign_edit_versions(%{assigns: %{ferret_service: ferret_service, live_action: live_action}} = socket)
       when live_action == :edit_versions do
    assign(socket, :edit_versions, ControlServer.Audit.history(ferret_service))
  end

  defp maybe_assign_edit_versions(socket), do: socket

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply, assign_pods(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    {:ok, _} = FerretDB.delete_ferret_service(socket.assigns.ferret_service)

    {:noreply, push_navigate(socket, to: ~p"/ferretdb")}
  end

  defp edit_url(ferret_service), do: ~p"/ferretdb/#{ferret_service}/edit"
  defp show_url(ferret_service), do: ~p"/ferretdb/#{ferret_service}/show"
  defp edit_versions_url(ferret_service), do: ~p"/ferretdb/#{ferret_service}/edit_versions"

  defp main_page(assigns) do
    ~H"""
    <.page_header title={"FerretDB Service: #{@ferret_service.name}"} back_link={~p"/ferretdb"}>
      <:menu>
        <.badge :if={@ferret_service.project_id}>
          <:item label="Project" navigate={~p"/projects/#{@ferret_service.project_id}/show"}>
            {@ferret_service.project.name}
          </:item>
        </.badge>
      </:menu>

      <.flex>
        <.tooltip :if={@timeline_installed} target_id="history-tooltip">Edit History</.tooltip>
        <.tooltip target_id="edit-tooltip">Edit Service</.tooltip>
        <.tooltip target_id="delete-tooltip">Delete Service</.tooltip>
        <.flex gaps="0">
          <.button
            :if={@timeline_installed}
            id="history-tooltip"
            variant="icon"
            icon={:clock}
            link={edit_versions_url(@ferret_service)}
          />
          <.button id="edit-tooltip" variant="icon" icon={:pencil} link={edit_url(@ferret_service)} />
          <.button
            id="delete-tooltip"
            variant="icon"
            icon={:trash}
            phx-click="delete"
            data-confirm="Are you sure?"
          />
        </.flex>
      </.flex>
    </.page_header>

    <.grid columns={%{sm: 1, lg: 2}}>
      <.panel title="Details" variant="gray">
        <.data_list>
          <:item title="Instances">
            {@ferret_service.instances}
          </:item>
          <:item :if={@ferret_service.memory_limits} title="Memory Limits">
            {Memory.humanize(@ferret_service.memory_limits)}
          </:item>
          <:item title="Started">
            <.relative_display time={@ferret_service.inserted_at} />
          </:item>
        </.data_list>
      </.panel>

      <.flex column class="justify-start">
        <%!-- TODO: services link and any other relavent links --%>
      </.flex>

      <.panel title="Pods" class="col-span-2">
        <.pods_table pods={@pods} />
      </.panel>
    </.grid>
    """
  end

  defp edit_versions_page(assigns) do
    ~H"""
    <.page_header title="Edit History" back_link={show_url(@ferret_service)} />
    <.panel title="Edit History">
      <.edit_versions_table rows={@edit_versions} abridged />
    </.panel>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <%= case @live_action do %>
      <% :show -> %>
        <.main_page
          ferret_service={@ferret_service}
          pods={@pods}
          page_title={@page_title}
          timeline_installed={@timeline_installed}
        />
      <% :edit_versions -> %>
        <.edit_versions_page ferret_service={@ferret_service} edit_versions={@edit_versions} />
    <% end %>
    """
  end
end

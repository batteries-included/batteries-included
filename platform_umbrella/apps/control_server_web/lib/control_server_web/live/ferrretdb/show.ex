defmodule ControlServerWeb.Live.FerretServiceShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ActionsDropdown
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
    assign(socket, :timeline_installed, SummaryBatteries.battery_installed?(:timeline))
  end

  defp assign_current_page(socket) do
    assign(socket, current_page: :data)
  end

  defp assign_page_title(%{assigns: %{live_action: :show}} = socket) do
    assign(socket, page_title: "Show FerretDB Service")
  end

  defp assign_page_title(%{assigns: %{live_action: :pods}} = socket) do
    assign(socket, page_title: "Show FerretDB Pods")
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

  defp maybe_assign_edit_versions(%{assigns: %{ferret_service: ferret_service, live_action: :edit_versions}} = socket) do
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
  defp pods_url(ferret_service), do: ~p"/ferretdb/#{ferret_service}/pods"
  defp edit_versions_url(ferret_service), do: ~p"/ferretdb/#{ferret_service}/edit_versions"

  defp ferret_page_header(assigns) do
    ~H"""
    <.page_header title={"#{@page_title}: #{@ferret_service.name}"} back_link={~p"/ferretdb"}>
      <:menu>
        <.badge :if={@ferret_service.project_id}>
          <:item label="Project" navigate={~p"/projects/#{@ferret_service.project_id}/show"}>
            {@ferret_service.project.name}
          </:item>
        </.badge>
      </:menu>

      <.flex>
        <.actions_dropdown>
          <.dropdown_link navigate={edit_url(@ferret_service)} icon={:pencil}>
            Edit FerretDB
          </.dropdown_link>

          <.dropdown_button
            class="w-full"
            icon={:trash}
            phx-click="delete"
            data-confirm={"Are you sure you want to delete the \"#{@ferret_service.name}\" FerretDB Service?"}
          >
            Delete FerretDB
          </.dropdown_button>
        </.actions_dropdown>
      </.flex>
    </.page_header>
    """
  end

  defp links_panel(assigns) do
    ~H"""
    <.panel variant="gray">
      <.tab_bar variant="navigation">
        <:tab selected={@live_action == :show} patch={show_url(@ferret_service)}>Overview</:tab>
        <:tab selected={@live_action == :pods} patch={pods_url(@ferret_service)}>Pods</:tab>
        <:tab
          :if={@timeline_installed}
          selected={@live_action == :edit_versions}
          patch={edit_versions_url(@ferret_service)}
        >
          Edit Versions
        </:tab>
      </.tab_bar>
    </.panel>
    """
  end

  defp main_page(assigns) do
    ~H"""
    <.ferret_page_header ferret_service={@ferret_service} page_title={@page_title} />
    <.grid columns={%{sm: 1, lg: 4}}>
      <.panel title="Details" class="lg:col-span-3">
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

      <.links_panel
        ferret_service={@ferret_service}
        live_action={@live_action}
        timeline_installed={@timeline_installed}
      />
    </.grid>
    """
  end

  defp edit_versions_page(assigns) do
    ~H"""
    <.ferret_page_header ferret_service={@ferret_service} page_title={@page_title} />
    <.grid columns={%{sm: 1, lg: 4}}>
      <.panel title="Edit History" class="lg:col-span-3">
        <.edit_versions_table rows={@edit_versions} abridged />
      </.panel>

      <.links_panel
        ferret_service={@ferret_service}
        live_action={@live_action}
        timeline_installed={@timeline_installed}
      />
    </.grid>
    """
  end

  defp pods_page(assigns) do
    ~H"""
    <.ferret_page_header ferret_service={@ferret_service} page_title={@page_title} />
    <.grid columns={%{sm: 1, lg: 4}}>
      <.panel title="Pods" class="lg:col-span-3">
        <.pods_table pods={@pods} />
      </.panel>

      <.links_panel
        ferret_service={@ferret_service}
        live_action={@live_action}
        timeline_installed={@timeline_installed}
      />
    </.grid>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <%= case @live_action do %>
      <% :show -> %>
        <.main_page
          ferret_service={@ferret_service}
          live_action={@live_action}
          page_title={@page_title}
          timeline_installed={@timeline_installed}
        />
      <% :edit_versions -> %>
        <.edit_versions_page
          ferret_service={@ferret_service}
          live_action={@live_action}
          page_title={@page_title}
          timeline_installed={@timeline_installed}
          edit_versions={@edit_versions}
        />
      <% :pods -> %>
        <.pods_page
          ferret_service={@ferret_service}
          live_action={@live_action}
          pods={@pods}
          page_title={@page_title}
          timeline_installed={@timeline_installed}
        />
    <% end %>
    """
  end
end

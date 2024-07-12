defmodule ControlServerWeb.Live.MagicHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.SnapshotApplyAlert
  import ControlServerWeb.UmbrellaSnapshotsTable

  alias CommonCore.Batteries.Catalog
  alias ControlServer.SnapshotApply.Umbrella
  alias EventCenter.KubeSnapshot, as: KubeSnapshotEventCenter
  alias KubeServices.SnapshotApply.Worker
  alias KubeServices.SystemState.SummaryBatteries

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    :ok = KubeSnapshotEventCenter.subscribe()

    {:ok,
     socket
     |> assign_snapshots()
     |> assign_batteries()
     |> assign_deploys_running()
     |> assign_catalog_group()
     |> assign_current_page()
     |> assign_page_title()}
  end

  defp assign_batteries(socket) do
    assign(socket, batteries: SummaryBatteries.installed_batteries())
  end

  defp assign_deploys_running(socket) do
    assign(socket, deploys_running: Worker.get_running())
  end

  def assign_snapshots(socket) do
    snaps = Umbrella.latest_umbrella_snapshots()
    assign(socket, :snapshots, snaps)
  end

  defp assign_catalog_group(socket) do
    assign(socket, catalog_group: Catalog.group(:magic))
  end

  defp assign_current_page(socket) do
    assign(socket, current_page: socket.assigns.catalog_group.type)
  end

  defp assign_page_title(socket) do
    assign(socket, page_title: socket.assigns.catalog_group.name)
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply,
     socket
     |> assign_snapshots()
     |> assign_batteries()
     |> assign_deploys_running()}
  end

  @impl Phoenix.LiveView
  def handle_event("start-deploy", _params, socket) do
    _ = Worker.start()
    {:noreply, assign_snapshots(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("pause-deploy", _params, socket) do
    _ = Worker.set_running(false)
    {:noreply, assign_deploys_running(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("resume-deploy", _params, socket) do
    _ = Worker.set_running(true)
    {:noreply, assign_deploys_running(socket)}
  end

  defp battery_link_panel(%{battery: %{type: :timeline}} = assigns) do
    ~H"""
    <.a variant="bordered" navigate={~p"/history/timeline"}>Timeline</.a>
    <.a variant="bordered" navigate={~p"/edit_versions"}>Edit Versions</.a>
    """
  end

  defp battery_link_panel(%{battery: %{type: :stale_resource_cleaner}} = assigns) do
    ~H"""
    <.a variant="bordered" navigate={~p"/deleted_resources"}>Deleted Resources</.a>
    <.a variant="bordered" navigate={~p"/stale"}>Delete Queue</.a>
    """
  end

  defp battery_link_panel(%{battery: %{type: :battery_core}} = assigns) do
    ~H"""
    <.a variant="bordered" href="http://home.127-0-0-1.batrsinc.co:4900/">
      Batteries Included Home
    </.a>
    <.a variant="bordered" navigate={~p"/content_addressable"}>Content Addressable Storage</.a>
    """
  end

  defp battery_link_panel(assigns), do: ~H||

  defp deploys_panel(assigns) do
    ~H"""
    <.panel title="Deploys">
      <:menu>
        <.flex>
          <.a :if={@deploys_running} phx-click="pause-deploy">
            <.icon name={:pause} class="inline-flex h-5 w-auto my-auto mr-2" />Pause Deploys
          </.a>
          <.a :if={!@deploys_running} phx-click="resume-deploy">
            <.icon name={:play} class="inline-flex h-5 w-auto my-auto mr-2" />Resume Deploys
          </.a>
          <.a :if={@deploys_running} phx-click="start-deploy">
            <.icon name={:plus} class="inline-flex h-5 w-auto my-auto mr-2" />Start Deploy
          </.a>
          <.link navigate={~p"/deploy"}>View All</.link>
        </.flex>
      </:menu>
      <.pause_alert :if={!@deploys_running} />
      <.umbrella_snapshots_table abridged snapshots={@snapshots} />
    </.panel>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title}>
      <.button variant="secondary" icon={:kubernetes} link={~p"/batteries/magic"}>
        Manage Batteries
      </.button>
    </.page_header>
    <.grid columns={%{sm: 1, lg: 2}} class="w-full">
      <.deploys_panel deploys_running={@deploys_running} snapshots={@snapshots} />
      <.flex column class="justify-start">
        <.battery_link_panel :for={battery <- @batteries} battery={battery} />
      </.flex>
    </.grid>
    """
  end
end

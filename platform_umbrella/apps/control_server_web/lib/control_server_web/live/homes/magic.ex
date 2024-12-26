defmodule ControlServerWeb.Live.MagicHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.SnapshotApplyAlert
  import ControlServerWeb.UmbrellaSnapshotsTable

  alias CommonCore.Batteries.Catalog
  alias ControlServer.SnapshotApply.Umbrella
  alias EventCenter.SystemStateSummary, as: SystemStateSummaryEventCenter
  alias KubeServices.SnapshotApply.Worker
  alias KubeServices.SystemState.SummaryBatteries

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :ok = SystemStateSummaryEventCenter.subscribe()
    end

    {:ok,
     socket
     |> assign_snapshots()
     |> assign_batteries()
     |> assign_deploys_running()
     |> assign_catalog_group()
     |> assign_current_page()
     |> assign_page_title()}
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

  defp home_base_url(config) do
    config
    |> CommonCore.ET.URLs.home_base_url()
    |> URI.new!()
    |> Map.put(:path, "/")
    |> URI.to_string()
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

  defp battery_link_panel(%{battery: %{type: :battery_core, config: config}} = assigns) do
    assigns = assign(assigns, :home_base_url, home_base_url(config))

    ~H"""
    <.a variant="bordered" href={@home_base_url}>
      Batteries Included Home
    </.a>
    <.a variant="bordered" navigate={~p"/state_summary"}>Latest State Summary</.a>
    <.a variant="bordered" navigate={~p"/content_addressable"}>Content Addressable Storage</.a>
    """
  end

  defp battery_link_panel(assigns), do: ~H||

  defp deploys_panel(assigns) do
    ~H"""
    <.panel title="Deploys">
      <:menu>
        <.flex>
          <.button :if={@deploys_running} icon={:play} phx-click="start-deploy">Start Deploy</.button>
          <.button :if={@deploys_running} icon={:pause} phx-click="pause-deploy">
            Pause Deploys
          </.button>
          <.button :if={!@deploys_running} icon={:arrow_path} phx-click="resume-deploy">
            Resume Deploys
          </.button>
          <.button variant="minimal" link={~p"/deploy"}>View All</.button>
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

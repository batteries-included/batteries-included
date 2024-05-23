defmodule ControlServerWeb.Live.MagicHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.SnapshotApplyAlert
  import ControlServerWeb.UmbrellaSnapshotsTable

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
     |> assign_current_page()}
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

  defp assign_current_page(socket) do
    assign(socket, current_page: :magic)
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
    <.bordered_menu_item navigate={~p"/history/timeline"} title="Timeline" />
    <.bordered_menu_item navigate={~p"/edit_versions"} title="Edit Versions" />
    """
  end

  defp battery_link_panel(%{battery: %{type: :stale_resource_cleaner}} = assigns) do
    ~H"""
    <.bordered_menu_item navigate={~p"/deleted_resources"} title="Deleted Resources" />
    <.bordered_menu_item navigate={~p"/stale"} title="Delete Queue" />
    """
  end

  defp battery_link_panel(%{battery: %{type: :battery_core}} = assigns) do
    ~H"""
    <.bordered_menu_item
      href="http://home.127.0.0.1.ip.batteriesincl.com:4900/"
      title="Batteries Included Home"
    />
    <.bordered_menu_item navigate={~p"/content_addressable"} title="Content Addressable Storage" />
    """
  end

  defp battery_link_panel(assigns), do: ~H||

  defp deploys_panel(assigns) do
    ~H"""
    <.panel title="Deploys">
      <:menu>
        <.flex>
          <.a :if={@deploys_running} phx-click="pause-deploy" variant="styled">
            <.icon name={:pause} class="inline-flex h-5 w-auto my-auto mr-2" />Pause Deploys
          </.a>
          <.a :if={!@deploys_running} phx-click="resume-deploy" variant="styled">
            <.icon name={:play} class="inline-flex h-5 w-auto my-auto mr-2" />Resume Deploys
          </.a>
          <.a :if={@deploys_running} phx-click="start-deploy" variant="styled">
            <.icon name={:plus} class="inline-flex h-5 w-auto my-auto mr-2" />Start Deploy
          </.a>
          <.a navigate={~p"/deploy"}>View All</.a>
        </.flex>
      </:menu>
      <.pause_alert :if={!@deploys_running} />
      <.umbrella_snapshots_table abbridged snapshots={@snapshots} />
    </.panel>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Magic">
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

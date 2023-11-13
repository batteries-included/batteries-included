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
     |> assign_deploys_running()}
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
    <.panel>
      <.a navigate={~p"/history/timeline"} variant="styled">Timeline</.a>
    </.panel>
    """
  end

  defp battery_link_panel(%{battery: %{type: :stale_resource_cleaner}} = assigns) do
    ~H"""
    <.panel>
      <.a navigate={~p"/stale"} variant="styled">Delete Queue</.a>
    </.panel>
    """
  end

  defp battery_link_panel(%{battery: %{type: :battery_core}} = assigns) do
    ~H"""
    <.panel>
      <.a navigate={~p"/deleted_resources"} variant="styled">Deleted Resources</.a>
    </.panel>
    <.panel>
      <.a navigate={~p"/content_addressable"} variant="styled">Content Addressable Storage</.a>
    </.panel>
    <.panel>
      <.a href="http://home.127.0.0.1.ip.batteriesincl.com:4900/" variant="external">
        Batteries Included Home
      </.a>
    </.panel>
    """
  end

  defp battery_link_panel(assigns), do: ~H||

  defp deploys_panel(assigns) do
    ~H"""
    <.panel title="Deploys">
      <:top_right>
        <.flex>
          <.a :if={@deploys_running} phx-click="pause-deploy" variant="styled">
            <PC.icon name={:pause} class="inline-flex h-5 w-auto my-auto mr-2" />Pause Deploys
          </.a>
          <.a :if={!@deploys_running} phx-click="resume-deploy" variant="styled">
            <PC.icon name={:play} class="inline-flex h-5 w-auto my-auto mr-2" />Resume Deploys
          </.a>
          <.a :if={@deploys_running} phx-click="start-deploy" variant="styled">
            <PC.icon name={:plus} class="inline-flex h-5 w-auto my-auto mr-2" />Start Deploy
          </.a>
          <.a navigate={~p"/deploy"}>View All</.a>
        </.flex>
      </:top_right>
      <.pause_alert :if={!@deploys_running} />
      <.umbrella_snapshots_table abbridged snapshots={@snapshots} />
    </.panel>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Magic">
      <:right_side>
        <PC.button
          label="Manage Batteries"
          color="light"
          to={~p"/batteries/magic"}
          link_type="live_redirect"
        />
      </:right_side>
    </.page_header>
    <.grid columns={%{sm: 1, lg: 2}} class="w-full">
      <.deploys_panel deploys_running={@deploys_running} snapshots={@snapshots} />
      <.flex class="flex-col items-stretch justify-start">
        <.battery_link_panel :for={battery <- @batteries} battery={battery} />
      </.flex>
    </.grid>
    """
  end
end

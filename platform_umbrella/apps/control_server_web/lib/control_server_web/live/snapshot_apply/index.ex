defmodule ControlServerWeb.Live.SnapshotApplyIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.UmbrellaSnapshotsTable

  alias ControlServer.SnapshotApply.Umbrella
  alias EventCenter.KubeSnapshot, as: KubeSnapshotEventCenter

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    :ok = KubeSnapshotEventCenter.subscribe()
    {:ok, assign_snapshots(socket)}
  end

  def assign_snapshots(socket) do
    {:ok, {snaps, _}} = Umbrella.paginated_umbrella_snapshots()
    assign(socket, :snapshots, snaps)
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply, assign_snapshots(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("start", _, socket) do
    _ = KubeServices.SnapshotApply.Worker.start()
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header
      title="Deploys"
      back_button={%{link_type: "live_redirect", to: ~p"/batteries/magic"}}
    >
      <:right_side>
        <.button phx-click="start">
          Start Deploy
        </.button>
      </:right_side>
    </.page_header>
    <.panel title="Status">
      <.umbrella_snapshots_table snapshots={@snapshots} />
    </.panel>
    """
  end
end

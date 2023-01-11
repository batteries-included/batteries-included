defmodule ControlServerWeb.Live.SnapshotApplyIndex do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.KubeSnapshotsTable

  alias ControlServer.SnapshotApply
  alias EventCenter.KubeSnapshot, as: SnapshotEventCenter

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    :ok = SnapshotEventCenter.subscribe()
    {:ok, assign(socket, :snapshots, snapshots([]))}
  end

  def snapshots(params) do
    SnapshotApply.paginated_kube_snapshots(params)
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply, assign(socket, :snapshots, snapshots([]))}
  end

  @impl Phoenix.LiveView
  def handle_event("start", _, socket) do
    job = KubeServices.SnapshotApply.Worker.start!()

    Logger.debug("Started oban Job #{job.id}")

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.layout group={:magic} active={:kube_snapshots}>
      <:title>
        <.title>Kube Deploys</.title>
      </:title>
      <.kube_snapshots_table kube_snapshots={@snapshots.entries} />

      <.h2 variant="fancy">Actions</.h2>
      <.body_section>
        <.button phx-click="start">
          Start Deploy
        </.button>
      </.body_section>
    </.layout>
    """
  end
end

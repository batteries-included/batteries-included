defmodule ControlServerWeb.Live.SnapshotApplyIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

  import ControlServerWeb.KubeSnapshotsTable

  alias ControlServer.SnapshotApply.Kube
  alias EventCenter.KubeSnapshot, as: KubeSnapshotEventCenter

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    :ok = KubeSnapshotEventCenter.subscribe()
    {:ok, assign_snapshots(socket)}
  end

  def assign_snapshots(socket) do
    assign(socket, :snapshots, Kube.paginated_kube_snapshots())
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
    <.h1>Deploys</.h1>
    <.kube_snapshots_table kube_snapshots={elem(@snapshots, 0)} />

    <.h2 variant="fancy">Actions</.h2>
    <.card>
      <.button phx-click="start">
        Start Deploy
      </.button>
    </.card>
    """
  end
end

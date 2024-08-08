defmodule ControlServerWeb.Live.SnapshotApplyIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.SnapshotApplyAlert
  import ControlServerWeb.UmbrellaSnapshotsTable

  alias ControlServer.SnapshotApply.Umbrella
  alias EventCenter.KubeSnapshot, as: KubeSnapshotEventCenter
  alias KubeServices.SnapshotApply.Worker

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    :ok = KubeSnapshotEventCenter.subscribe()
    {:ok, assign_deploys_running(socket)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    with {:ok, {snapshots, meta}} <- Umbrella.list_umbrella_snapshots(params) do
      {:noreply,
       socket
       |> assign(:meta, meta)
       |> assign(:snapshots, snapshots)}
    end
  end

  defp assign_deploys_running(socket) do
    assign(socket, deploys_running: Worker.get_running())
  end

  @impl Phoenix.LiveView
  def handle_event("start-deploy", _params, socket) do
    _ = Worker.start()
    {:noreply, push_patch(socket, to: ~p"/deploy")}
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

  @impl Phoenix.LiveView
  def handle_info(_, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Deploys" back_link={~p"/magic"}>
      <.button :if={@deploys_running} variant="dark" icon={:play} phx-click="start-deploy">
        Start Deploy
      </.button>
    </.page_header>

    <.panel title="All Deploys">
      <.pause_alert :if={!@deploys_running} />
      <.umbrella_snapshots_table snapshots={@snapshots} meta={@meta} />
    </.panel>
    """
  end
end

defmodule ControlServerWeb.Live.KubeSnapshotList do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import CommonUI.Table

  alias ControlServer.SnapshotApply
  alias EventCenter.KubeSnapshot, as: SnapshotEventCenter

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    :ok = SnapshotEventCenter.subscribe()
    {:ok, assign(socket, :snapshots, snapshots([]))}
  end

  def snapshots(params) do
    SnapshotApply.paginated_kube_snapshots(params)
  end

  @impl true
  def handle_info(_unused, socket) do
    {:noreply, assign(socket, :snapshots, snapshots([]))}
  end

  @impl true
  def handle_event("start", _, socket) do
    job = KubeServices.SnapshotApply.CreationWorker.start!()

    Logger.debug("Started oban Job #{job.id}")

    {:noreply, socket}
  end

  defp row(assigns) do
    ~H"""
    <.tr>
      <.td>
        <%= @snapshot.inserted_at %>
      </.td>
      <.td>
        <%= @snapshot.status %>
      </.td>
      <.td>
        <.link to={snapshot_path(@snapshot)}>View</.link>
      </.td>
    </.tr>
    """
  end

  defp snapshot_path(snapshot) do
    Routes.kube_snapshot_show_path(ControlServerWeb.Endpoint, :index, snapshot.id)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Kube Deploys</.title>
      </:title>
      <:left_menu>
        <.magic_menu active="snapshots" />
      </:left_menu>
      <.body_section>
        <.table>
          <.thead>
            <.tr>
              <.th>
                Started
              </.th>
              <.th>
                Status
              </.th>
            </.tr>
          </.thead>
          <%= for snapshot <- @snapshots.entries do %>
            <.row snapshot={snapshot} />
          <% end %>
        </.table>
      </.body_section>

      <.h3>Actions</.h3>
      <.body_section>
        <.button phx_click="start">
          Start Deploy
        </.button>
      </.body_section>
    </.layout>
    """
  end
end

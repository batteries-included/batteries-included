defmodule ControlServerWeb.Live.KubeSnapshotList do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import CommonUI.Table

  alias ControlServer.SnapshotApply

  require Logger

  @impl true
  def mount(params, _session, socket) do
    Logger.debug("Params => #{inspect(params)}")

    {:ok, assign(socket, :snapshots, snapshots([]))}
  end

  def snapshots(_params) do
    SnapshotApply.paginated_kube_snapshots()
  end

  defp row(assigns) do
    ~H"""
    <.tr>
      <.td>
        <%= @snapshot.id %>
      </.td>
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
                Id
              </.th>
              <.th>
                Inserted At
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
    </.layout>
    """
  end
end

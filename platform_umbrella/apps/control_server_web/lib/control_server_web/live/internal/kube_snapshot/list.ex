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
        View
      </.td>
    </.tr>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Snapshots</.title>
      </:title>
      <:left_menu>
        <.magic_menu active={"#{@live_action}"} />
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

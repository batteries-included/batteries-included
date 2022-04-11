defmodule ControlServerWeb.Live.WorkerList do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import CommonUI.Table

  alias ControlServer.Services
  alias KubeRawResources.Resource.ResourceState
  alias KubeServices.Worker

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :service_states, servce_states())}
  end

  def servce_states do
    Services.all()
    |> Enum.map(&get_state/1)
    |> Enum.to_list()
  end

  def get_state(base_service), do: Worker.get_state(base_service)

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.layout>
      <.body_section>
        <.services_table states={@service_states} />
      </.body_section>
    </.layout>
    """
  end

  defp services_table(assigns) do
    ~H"""
    <.table>
      <.thead>
        <.tr>
          <.th>
            Service ID
          </.th>
          <.th>
            Service Type
          </.th>
          <.th>
            Num Resources
          </.th>
          <.th>
            Num UnSync'd
          </.th>
        </.tr>
      </.thead>
      <.tbody>
        <%= for entry <- @states do %>
          <.row state={entry} />
        <% end %>
      </.tbody>
    </.table>
    """
  end

  defp row(assigns) do
    ~H"""
    <.tr>
      <.td class="font-medium">
        <%= @state.base_service.id %>
      </.td>
      <.td><%= @state.base_service.service_type %></.td>
      <.td><%= map_size(@state.requested_resources) %></.td>
      <.td><%= count_not_ok(@state.path_state_map) %></.td>
    </.tr>
    """
  end

  defp count_not_ok(path_state_map) do
    path_state_map
    |> Enum.filter(fn {_path, value} -> !ResourceState.ok?(value) end)
    |> Enum.count()
  end
end

defmodule ControlServerWeb.Live.WorkerList do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout

  alias ControlServer.Services
  alias KubeRawResources.Resource.ResourceState
  alias KubeServices.Worker

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :service_states, servce_states())}
  end

  def servce_states do
    Services.list_base_services()
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
        <.table states={@service_states} />
      </.body_section>
    </.layout>
    """
  end

  defp table(assigns) do
    ~H"""
    <table class="min-w-full divide-y divide-gray-200">
      <thead>
        <tr>
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
        </tr>
      </thead>
      <tbody>
        <%= for entry <- @states do %>
          <.row state={entry} />
        <% end %>
      </tbody>
    </table>
    """
  end

  defp th(assigns) do
    ~H"""
    <th
      scope="col"
      class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase"
    >
      <%= render_slot(@inner_block) %>
    </th>
    """
  end

  defp row(assigns) do
    ~H"""
    <tr>
      <.id_td>
        <%= @state.base_service.id %>
      </.id_td>
      <.standard_td><%= @state.base_service.service_type %></.standard_td>
      <.standard_td><%= map_size(@state.requested_resources) %></.standard_td>
      <.standard_td><%= count_not_ok(@state.path_state_map) %></.standard_td>
    </tr>
    """
  end

  defp count_not_ok(path_state_map) do
    path_state_map
    |> Enum.filter(fn {_path, value} -> !ResourceState.ok?(value) end)
    |> Enum.count()
  end

  defp id_td(assigns) do
    ~H"""
    <td class="px-6 py-4 text-sm font-medium text-gray-900 whitespace-nowrap">
      <%= render_slot(@inner_block) %>
    </td>
    """
  end

  defp standard_td(assigns) do
    ~H"""
    <td class="px-6 py-4 text-sm text-gray-500 whitespace-nowrap">
      <%= render_slot(@inner_block) %>
    </td>
    """
  end
end

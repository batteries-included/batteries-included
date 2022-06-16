defmodule ControlServerWeb.RunnableServiceList do
  use ControlServerWeb, :component

  import CommonUI.Table
  import CommonUI.Icons.Misc

  alias Phoenix.Naming

  defp assign_defaults(assigns) do
    assigns
    |> assign_new(:base_services, fn -> [] end)
    |> assign_new(:runnable_services, fn -> [] end)
  end

  defp is_active(runnable_service, base_services) do
    Enum.any?(base_services, fn bs -> bs.service_type == runnable_service.service_type end)
  end

  def services_table(assigns) do
    assigns = assign_defaults(assigns)

    ~H"""
    <div>
      <.table>
        <.thead>
          <.tr>
            <.th>
              Service Type
            </.th>
            <.th>
              Start
            </.th>
          </.tr>
        </.thead>
        <.tbody>
          <%= for runnable_service <- @runnable_services do %>
            <.table_row runnable_service={runnable_service} base_services={@base_services} />
          <% end %>
        </.tbody>
      </.table>
    </div>
    """
  end

  def table_row(assigns) do
    ~H"""
    <.tr>
      <.td>
        <%= Naming.humanize(@runnable_service.service_type) %>
      </.td>
      <.td>
        <%= if not is_active(@runnable_service, @base_services) do %>
          <.start_button runnable_service={@runnable_service} />
        <% else %>
          <.running />
        <% end %>
      </.td>
    </.tr>
    """
  end

  def start_button(assigns) do
    ~H"""
    <.button
      label="Start Service"
      variant="shadow"
      phx-click={:start}
      phx-value-service-type={@runnable_service.service_type}
    />
    """
  end

  defp running(assigns) do
    ~H"""
    <div class="flex">
      <div class="flex-initial">
        Started
      </div>
      <div class="flex-none ml-5">
        <.check_mark class="text-shamrock-500" />
      </div>
    </div>
    """
  end
end

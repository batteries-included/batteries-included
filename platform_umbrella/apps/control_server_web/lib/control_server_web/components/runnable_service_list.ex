defmodule ControlServerWeb.RunnableServiceList do
  use ControlServerWeb, :component

  import CommonUI.Table

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
      <.h4>Runnable Services</.h4>
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
          <.button
            label="Start Service"
            variant="shadow"
            phx-click={:start}
            phx-value-service-type={@runnable_service.service_type}
          />
        <% end %>
      </.td>
    </.tr>
    """
  end
end

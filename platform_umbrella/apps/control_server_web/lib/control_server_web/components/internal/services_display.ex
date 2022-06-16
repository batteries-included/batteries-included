defmodule ControlServerWeb.ServicesDisplay do
  use ControlServerWeb, :component

  import CommonUI.Table

  def services_display(assigns) do
    ~H"""
    <.table>
      <.thead>
        <.tr>
          <.th>
            Namespace
          </.th>
          <.th>
            Name
          </.th>
          <.th>
            Cluster IP
          </.th>
          <.th>
            Ports
          </.th>
        </.tr>
      </.thead>
      <.tbody>
        <%= for service <- @services do %>
          <.service_row service={service} />
        <% end %>
      </.tbody>
    </.table>
    """
  end

  defp service_row(assigns) do
    ~H"""
    <.tr>
      <.td>
        <%= @service["metadata"]["namespace"] %>
      </.td>
      <.td>
        <%= @service["metadata"]["name"] %>
      </.td>
      <.td>
        <%= @service["spec"]["clusterIP"] %>
      </.td>
      <.td>
        <%= ports(@service) %>
      </.td>
    </.tr>
    """
  end

  defp ports(service) do
    service
    |> Map.get("spec", %{})
    |> Map.get("ports", [])
    |> Enum.map_join(", ", fn p -> Map.get(p, "port", 0) end)
  end
end

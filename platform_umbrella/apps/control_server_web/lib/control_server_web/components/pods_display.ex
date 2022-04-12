defmodule ControlServerWeb.PodsDisplay do
  use Phoenix.Component

  import CommonUI.Table

  def pods_display(assigns) do
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
            Status
          </.th>
          <.th>Restarts</.th>
          <.th>
            Age
          </.th>
        </.tr>
      </.thead>
      <.tbody>
        <%= for pod <- @pods do %>
          <.pod_row pod={pod} />
        <% end %>
      </.tbody>
    </.table>
    """
  end

  defp pod_row(assigns) do
    ~H"""
    <.tr>
      <.td>
        <%= @pod["metadata"]["namespace"] %>
      </.td>
      <.td>
        <%= @pod["metadata"]["name"] %>
      </.td>
      <.td>
        <%= @pod["status"]["phase"] %>
      </.td>
      <.td>
        <%= @pod["summary"]["restartCount"] %>
      </.td>
      <.td>
        <%= @pod["summary"]["fromStart"] %>
      </.td>
    </.tr>
    """
  end
end

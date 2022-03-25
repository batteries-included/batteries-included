defmodule ControlServerWeb.PodDisplay do
  use Phoenix.Component

  import CommonUI.Table
  import PetalComponents.Typography

  def pods_display(assigns) do
    ~H"""
    <.h3>
      Pods
    </.h3>
    <.table>
      <.thead>
        <.tr>
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

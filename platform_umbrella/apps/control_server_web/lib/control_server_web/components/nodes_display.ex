defmodule ControlServerWeb.NodesDisplay do
  use Phoenix.Component

  import CommonUI.Table

  def nodes_display(assigns) do
    ~H"""
    <.table>
      <.thead>
        <.tr>
          <.th>
            Name
          </.th>
          <.th>
            CPU
          </.th>
          <.th>
            Memory
          </.th>
          <.th>
            Kernel Version
          </.th>
          <.th>
            Kube Version
          </.th>
        </.tr>
      </.thead>
      <.tbody>
        <%= for node <- @nodes do %>
          <.node_row node={node} />
        <% end %>
      </.tbody>
    </.table>
    """
  end

  defp node_row(assigns) do
    ~H"""
    <.tr>
      <.td>
        <%= @node["metadata"]["name"] %>
      </.td>
      <.td>
        <%= @node["status"]["capacity"]["cpu"] %>
      </.td>
      <.td>
        <%= @node["status"]["capacity"]["memory"] %>
      </.td>
      <.td>
        <%= @node["status"]["nodeInfo"]["kernelVersion"] %>
      </.td>
      <.td>
        <%= @node["status"]["nodeInfo"]["kubeletVersion"] %>
      </.td>
    </.tr>
    """
  end
end

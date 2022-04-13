defmodule ControlServerWeb.StatefulSetsDisplay do
  use Phoenix.Component

  import CommonUI.Table

  def stateful_sets_display(assigns) do
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
            Replicas
          </.th>
          <.th>
            Available
          </.th>
        </.tr>
      </.thead>
      <.tbody>
        <%= for stateful_set <- @stateful_sets do %>
          <.stateful_set_row stateful_set={stateful_set} />
        <% end %>
      </.tbody>
    </.table>
    """
  end

  defp stateful_set_row(assigns) do
    ~H"""
    <.tr>
      <.td>
        <%= @stateful_set["metadata"]["namespace"] %>
      </.td>
      <.td>
        <%= @stateful_set["metadata"]["name"] %>
      </.td>
      <.td>
        <%= @stateful_set["spec"]["replicas"] %>
      </.td>
      <.td>
        <%= @stateful_set["status"]["availableReplicas"] %>
      </.td>
    </.tr>
    """
  end
end

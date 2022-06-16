defmodule ControlServerWeb.DeploymentsDisplay do
  use ControlServerWeb, :component

  import CommonUI.Table

  def deployments_display(assigns) do
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
        <%= for deployment <- @deployments do %>
          <.deployment_row deployment={deployment} />
        <% end %>
      </.tbody>
    </.table>
    """
  end

  defp deployment_row(assigns) do
    ~H"""
    <.tr>
      <.td>
        <%= @deployment["metadata"]["namespace"] %>
      </.td>
      <.td>
        <%= @deployment["metadata"]["name"] %>
      </.td>
      <.td>
        <%= @deployment["spec"]["replicas"] %>
      </.td>
      <.td>
        <%= @deployment["status"]["availableReplicas"] %>
      </.td>
    </.tr>
    """
  end
end

defmodule ControlServerWeb.PostgresClusterDisplay do
  use Phoenix.Component
  use CommonUI
  import CommonUI.Table
  import PetalComponents.Link

  alias ControlServerWeb.Router.Helpers, as: Routes

  def pg_cluster_display(assigns) do
    ~H"""
    <.table>
      <.thead>
        <.tr>
          <.th>
            Name
          </.th>
          <.th>
            Cluster Type
          </.th>
          <.th>
            Actions
          </.th>
        </.tr>
      </.thead>
      <tbody>
        <%= for {cluster, idx} <- Enum.with_index(@clusters) do %>
          <.cluster_row cluster={cluster} idx={idx} />
        <% end %>
      </tbody>
    </.table>
    """
  end

  defp cluster_row(assigns) do
    ~H"""
    <.tr>
      <.td>
        <%= @cluster.name %>
      </.td>
      <.td>
        <%= @cluster.type %>
      </.td>
      <.td>
        <span>
          <.link to={show_url(@cluster)} class="mt-8 text-lg font-medium text-left">
            Show Cluster
          </.link>
        </span>
      </.td>
    </.tr>
    """
  end

  defp show_url(cluster),
    do: Routes.postgres_show_path(ControlServerWeb.Endpoint, :show, cluster.id)
end

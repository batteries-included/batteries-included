defmodule ControlServerWeb.PostgresClusterDisplay do
  use Phoenix.Component
  import CommonUI.Table
  import PetalComponents.Typography
  import PetalComponents.Button
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
            Version
          </.th>
          <.th>
            Replicas
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

    <div class="ml-8 mt-15">
      <.button type="primary" variant="shadow" to={new_url()} link_type="live_patch">
        New Cluster
      </.button>
    </div>
    """
  end

  defp cluster_row(assigns) do
    ~H"""
    <.tr>
      <.td>
        <%= @cluster.name %>
      </.td>
      <.td>
        <%= @cluster.postgres_version %>
      </.td>
      <.td>
        <%= @cluster.num_instances %>
      </.td>
      <.td>
        <%= @cluster.type %>
      </.td>
      <.td>
        <span>
          <.link
            to={edit_url(@cluster)}
            class="mt-8 text-lg font-medium text-left"
            link_type="live_patch"
          >
            Edit Cluster
          </.link>
        </span>
      </.td>
    </.tr>
    """
  end

  defp edit_url(cluster),
    do: Routes.postgres_edit_path(ControlServerWeb.Endpoint, :edit, cluster.id)

  defp new_url, do: Routes.postgres_new_path(ControlServerWeb.Endpoint, :new)
end

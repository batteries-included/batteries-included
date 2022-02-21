defmodule ControlServerWeb.PostgresClusterDisplay do
  use Phoenix.Component
  use PetalComponents

  alias ControlServerWeb.Router.Helpers, as: Routes

  def pg_cluster_display(assigns) do
    ~H"""
    <.h3>
      Postgres Clusters
    </.h3>
    <table class="min-w-full divide-y divide-gray-200">
      <thead>
        <tr>
          <th
            scope="col"
            class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase"
          >
            Name
          </th>
          <th
            scope="col"
            class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase"
          >
            Version
          </th>
          <th
            scope="col"
            class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase"
          >
            Replicas
          </th>
          <th
            scope="col"
            class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase"
          >
            Actions
          </th>
        </tr>
      </thead>
      <tbody>
        <%= for {cluster, idx} <- Enum.with_index(@clusters) do %>
          <.cluster_row cluster={cluster} idx={idx} />
        <% end %>
      </tbody>
    </table>

    <.link to="/services/database/clusters/new" class="ml-8 mt-15">
      <.button type="primary">
        New Cluster
      </.button>
    </.link>
    """
  end

  defp cluster_row(assigns) do
    ~H"""
    <tr class="bg-white">
      <td scope="row" class="px-6 py-4 text-sm font-medium text-gray-900 whitespace-nowrap">
        <%= @cluster.name %>
      </td>
      <td class="px-6 py-4 text-sm text-gray-500 whitespace-nowrap">
        <%= @cluster.postgres_version %>
      </td>
      <td class="px-6 py-4 text-sm text-gray-500 whitespace-nowrap">
        <%= @cluster.num_instances %>
      </td>
      <td class="px-6 py-4 text-sm text-gray-500 whitespace-nowrap">
        <span>
          <.link to={cluster_edit_url(@cluster)} class="mt-8 text-lg font-medium text-left">
            Edit Cluster
          </.link>
        </span>
      </td>
    </tr>
    """
  end

  defp cluster_edit_url(cluster),
    do: Routes.services_postgres_edit_path(ControlServerWeb.Endpoint, :edit, cluster.id)
end

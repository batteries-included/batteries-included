defmodule ControlServerWeb.PgUserTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :users, :list, required: true
  attr :cluster, :any, required: true
  attr :id, :string, default: "pg-users-table"

  def pg_users_table(assigns) do
    ~H"""
    <.table id={@id} rows={@users}>
      <:col :let={user} label="User Name"><%= user.username %></:col>
      <:col :let={user} label="Roles"><%= Enum.join(user.roles, ", ") %></:col>
      <:col :let={user} label="Secret"><%= secret_name(@cluster, user.username) %></:col>
      <:col :let={user} label="Namespace"><%= namespaces(user.username, @cluster) %></:col>
    </.table>
    """
  end

  defp cluster_namespace(:internal = _cluster_type), do: CommonCore.Defaults.Namespaces.base()
  defp cluster_namespace(_cluster_type), do: CommonCore.Defaults.Namespaces.data()

  defp namespaces(user_name, cluster) do
    cluster.credential_copies
    |> Enum.filter(fn cc -> cc.username == user_name end)
    |> Enum.map(& &1.namespace)
    |> Enum.concat([cluster_namespace(cluster.type)])
    |> Enum.join(", ")
  end

  defp secret_name(cluster, username) do
    "#{username}.#{cluster.team_name}-#{cluster.name}.credentials.postgresql"
  end
end

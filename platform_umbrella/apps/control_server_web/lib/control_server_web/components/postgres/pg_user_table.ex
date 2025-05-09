defmodule ControlServerWeb.PgUserTable do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.Defaults.Namespaces
  alias CommonCore.StateSummary.PostgresState

  attr :users, :list, required: true
  attr :cluster, :any, required: true
  attr :id, :string, default: "pg-users-table"
  attr :opts, :list, default: []

  slot :action

  def pg_users_table(assigns) do
    ~H"""
    <.table id={@id} rows={Enum.with_index(@users)} opts={@opts}>
      <:col :let={{user, _user_index}} label="User Name">{user.username}</:col>
      <:col :let={{user, _user_index}} label="Roles">{Enum.join(user.roles, ", ")}</:col>
      <:col :let={{user, _user_index}} label="Secret">{secret_name(@cluster, user)}</:col>
      <:col :let={{user, _user_index}} label="Namespace">{namespaces(user, @cluster)}</:col>
      <:action :let={{user, user_index}} :if={@action}>
        {render_slot(@action, {user, user_index})}
      </:action>
    </.table>
    """
  end

  defp cluster_namespace(:internal = _cluster_type), do: Namespaces.base()
  defp cluster_namespace(_cluster_type), do: Namespaces.data()

  defp namespaces(user, cluster) do
    user.credential_namespaces
    |> Enum.concat([cluster_namespace(cluster.type)])
    |> Enum.uniq()
    |> Enum.join(", ")
  end

  defp secret_name(cluster, user) do
    # TODO: HACK alert
    #
    # There's nothing currently that needs postgres state.
    # When there is this should be replaced with the
    # kube_services version
    #
    # Until then we use fake state summary it's not used in naming the secret for a user
    PostgresState.user_secret(%{}, cluster, user)
  end
end

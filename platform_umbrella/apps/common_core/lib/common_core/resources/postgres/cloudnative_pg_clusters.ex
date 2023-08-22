defmodule CommonCore.Resources.CloudnativePGClusters do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "cloudnative-pg-clusters"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Postgres.PGUser
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.Secret

  multi_resource(:postgres_clusters, battery, state) do
    Enum.map(state.postgres_clusters, fn cluster ->
      cluster_resource(cluster, battery, state)
    end)
  end

  multi_resource(:role_secrets, battery, state) do
    Enum.flat_map(state.postgres_clusters, fn cluster ->
      Enum.map(cluster.users, fn user ->
        user_role_secret(user, cluster, battery, state)
      end)
    end)
  end

  defp cluster_namespace(%Cluster{type: :internal} = _cluster, state), do: base_namespace(state)
  defp cluster_namespace(%Cluster{type: _} = _cluster, state), do: data_namespace(state)

  defp role_secret_name(user, cluster), do: Enum.join(["cloudnative-pg", cluster.name, user.username], ".")

  def cluster_resource(%Cluster{} = cluster, _battery, state) do
    # TOTAL FUCKING HACK
    #
    # HACK ALERT
    #
    # CloudNativePG really only support clusters with a single database in the postgres instance.
    # Zalando supported creating databases on the fly from the crd.
    #
    # Meaning the expectations and ccapabilies don't match so we have to fix this.
    # So while we transition that way assume that there's only one database; the first in the list
    # failure to abide by the new rule will result in crashing.
    db = List.first(cluster.databases, %{database: "app", owner: "app"})

    :cloudnative_pg_cluster
    |> B.build_resource()
    |> B.name(cluster.name)
    |> B.namespace(cluster_namespace(cluster, state))
    |> B.owner_label(cluster.id)
    |> B.spec(%{
      instances: cluster.num_instances,
      storage: %{size: cluster.storage_size},
      enableSuperuserAccess: false,
      bootstrap: %{initdb: %{database: db.name, owner: db.owner, dataChecksums: true}},

      # Users are called roles in postgres just to confuse
      # the fuck out of us here.
      #
      # Roles also called users in the damn cli are also inheritable
      # bags of permissions.
      #
      # In this case we just use them as users.
      managed: %{
        roles:
          Enum.map(cluster.users, fn user ->
            pg_user_to_pg_role(user, cluster)
          end)
      }
    })
  end

  def user_role_secret(%PGUser{} = user, %Cluster{} = cluster, _battery, state) do
    data = Secret.encode(%{username: user.username, password: user.password})

    :secret
    |> B.build_resource()
    |> B.name(role_secret_name(user, cluster))
    |> B.namespace(cluster_namespace(cluster, state))
    |> B.data(data)
  end

  defp pg_user_to_pg_role(%PGUser{} = user, %Cluster{} = cluster) do
    # TODO(elliott): Figure the UI for this out better.
    # for now this grabs all the roles that are true.
    #
    #
    user.roles
    |> Enum.map(&{&1, true})
    |> Map.new()
    |> Map.merge(%{
      name: user.username,
      ensure: "present",
      passwordSecret: %{name: role_secret_name(user, cluster)}
    })
  end
end

defmodule KubeResources.Postgres do
  use KubeExt.ResourceGenerator

  import CommonCore.SystemState.Namespaces

  alias KubeExt.Builder, as: B

  @app_name "postgres"

  multi_resource(:postgres_clusters, battery, state) do
    Enum.map(state.postgres_clusters, fn cluster ->
      postgres(cluster, battery, state)
    end)
  end

  def postgres(%{} = cluster, _battery, state) do
    spec = postgres_spec(cluster)

    B.build_resource(:postgresql)
    |> B.namespace(namespace(cluster, state))
    |> B.name(full_name(cluster))
    |> B.app_labels(@app_name)
    |> B.label("sidecar.istio.io/inject", "false")
    |> B.spec(spec)
    |> add_owner(cluster)
  end

  defp namespace(%{type: :internal} = _cluster, state), do: base_namespace(state)
  defp namespace(%{type: _} = _cluster, state), do: data_namespace(state)

  defp postgres_spec(cluster) do
    %{
      "teamId" => cluster.team_name,
      "numberOfInstances" => cluster.num_instances,
      "postgresql" => %{
        "version" => cluster.postgres_version,
        "parameters" => %{
          "log_destination" => "stderr",
          "logging_collector" => "false",
          "password_encryption" => "scram-sha-256"
        }
      },
      "volume" => %{
        "size" => cluster.storage_size
      },
      "users" => spec_users(cluster),
      "databases" => spec_databases(cluster)
    }
  end

  defp full_name(%{} = cluster) do
    "#{cluster.team_name}-#{cluster.name}"
  end

  defp spec_users(%{} = cluster) do
    cluster
    |> Map.get(:users, [])
    |> Enum.map(fn u -> {u.username, u.roles} end)
    |> Map.new()
  end

  defp spec_databases(%{} = cluster) do
    cluster
    |> Map.get(:databases, [])
    |> Enum.map(fn c -> {c.name, c.owner} end)
    |> Map.new()
  end

  defp add_owner(resource, %{id: id} = _cluster), do: B.owner_label(resource, id)
  defp add_owner(resource, _), do: resource
end

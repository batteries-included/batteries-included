defmodule CommonCore.Resources.Postgres do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "postgres"

  import CommonCore.StateSummary.FromKubeState
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.Secret

  multi_resource(:postgres_clusters, battery, state) do
    Enum.map(state.postgres_clusters, fn cluster ->
      postgres(cluster, battery, state)
    end)
  end

  multi_resource(:credential_copy, battery, state) do
    Enum.flat_map(state.postgres_clusters, fn cluster ->
      credential_copies(cluster, battery, state)
    end)
  end

  def postgres(%{} = cluster, _battery, state) do
    spec = postgres_spec(cluster)

    :postgresql
    |> B.build_resource()
    |> B.namespace(namespace(cluster, state))
    |> B.name(full_name(cluster))
    |> B.label("sidecar.istio.io/inject", "false")
    |> B.spec(spec)
    |> add_owner(cluster)
  end

  def credential_copies(cluster, _battery, state) do
    cluster
    |> Map.get(:credential_copies, [])
    |> Enum.map(fn pg_credential_copy ->
      source_namespace = namespace(cluster, state)
      secret_name = secret_name(cluster, pg_credential_copy.username)

      with %{} = _dest_namespace <-
             find_state_resource(state, :namespace, pg_credential_copy.namespace),
           %{"data" => %{}} = source_secret <-
             find_state_resource(state, :secret, source_namespace, secret_name) do
        cred_copy(cluster, pg_credential_copy, source_secret, state)
      else
        _ ->
          nil
      end
    end)
    |> Enum.reject(fn r -> r == nil end)
  end

  defp cred_copy(cluster, pg_cred_copy, source_secret, state) do
    secret_name = secret_name(cluster, pg_cred_copy.username)
    source_data = extract_secret_data(source_secret)

    :secret
    |> B.build_resource()
    |> B.name(secret_name)
    |> B.namespace(pg_cred_copy.namespace)
    |> add_owner(cluster)
    |> B.data(credential_copy_spec(cluster, pg_cred_copy, source_data, state))
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
        "size" => Integer.to_string(cluster.storage_size)
      },
      "users" => spec_users(cluster),
      "databases" => spec_databases(cluster)
    }
  end

  defp credential_copy_spec(_cluster, %{format: :user_password} = _cc, source_data, _state) do
    Secret.encode(source_data)
  end

  defp credential_copy_spec(cluster, %{format: :user_password_host} = _cc, source_data, state) do
    %{}
    |> Map.put("username", Map.fetch!(source_data, "username"))
    |> Map.put("password", Map.fetch!(source_data, "password"))
    |> Map.put("hostname", hostname(cluster, state))
    |> Secret.encode()
  end

  defp credential_copy_spec(cluster, %{format: :dsn} = _cc, source_data, state) do
    username = Map.fetch!(source_data, "username")
    pass = Map.fetch!(source_data, "password")
    hostname = hostname(cluster, state)

    %{}
    |> Map.put("dsn", "postgresql://#{username}:#{pass}@#{hostname}")
    |> Secret.encode()
  end

  defp hostname(cluster, state) do
    namespace = namespace(cluster, state)
    "#{cluster.team_name}-#{cluster.name}.#{namespace}.svc"
  end

  defp full_name(%{} = cluster) do
    "#{cluster.team_name}-#{cluster.name}"
  end

  defp secret_name(cluster, username) do
    "#{username}.#{cluster.team_name}-#{cluster.name}.credentials.postgresql"
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

  defp extract_secret_data(resource) do
    resource |> Map.get("data", %{}) |> Secret.decode!()
  end
end

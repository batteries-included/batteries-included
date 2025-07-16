defmodule CommonCore.StateSummary.PostgresState do
  @moduledoc false

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Postgres.PGUser
  alias CommonCore.StateSummary

  @default_secret_name "cloudnative-pg.pg-unknown-cluster.unknown-user"

  @spec read_write_hostname(StateSummary.t(), Cluster.t() | nil) :: String.t()
  def read_write_hostname(%StateSummary{} = _state_summary, nil) do
    "unknown-cluster-rw.unknown-namespace.svc.cluster.local."
  end

  def read_write_hostname(%StateSummary{} = state_summary, %Cluster{} = cluster) do
    ns = cluster_namespace(state_summary, cluster)
    "pg-#{cluster.name}-rw.#{ns}.svc.cluster.local."
  end

  @spec cluster(StateSummary.t(), Keyword.t() | map()) :: nil | Cluster.t()
  def cluster(%StateSummary{postgres_clusters: clusters} = _state_summary, opts \\ []) do
    Enum.find(clusters, fn c ->
      Enum.all?(opts, fn {k, v} -> Map.get(c, k) == v end)
    end)
  end

  @spec cluster_namespace(StateSummary.t(), Cluster.t()) ::
          nil | binary
  def cluster_namespace(%StateSummary{} = state_summary, %Cluster{type: :internal} = _cluster),
    do: base_namespace(state_summary)

  def cluster_namespace(%StateSummary{} = state_summary, %Cluster{type: _} = _cluster), do: data_namespace(state_summary)

  @spec user_secret(
          StateSummary.t() | any(),
          Cluster.t() | nil,
          PGUser.t() | nil
        ) :: binary()
  def user_secret(_state_summary, nil = _cluster, nil = _user), do: @default_secret_name
  def user_secret(_state_summary, nil = _cluster, _user), do: @default_secret_name
  def user_secret(_state_summary, _cluster, nil = _user), do: @default_secret_name

  def user_secret(_state_summary, %Cluster{name: cluster_name} = _cluster, %PGUser{username: username} = _user) do
    Enum.join(["cloudnative-pg", "pg-" <> cluster_name, username], ".")
  end

  @spec password_for_user(
          StateSummary.t() | any(),
          Cluster.t() | nil,
          PGUser.t() | nil
        ) :: binary() | nil
  def password_for_user(_state_summary, nil = _cluster, nil = _user), do: nil
  def password_for_user(_state_summary, nil = _cluster, _user), do: nil
  def password_for_user(_state_summary, _cluster, nil = _user), do: nil

  def password_for_user(
        _state_summary,
        %Cluster{password_versions: versions} = _cluster,
        %PGUser{username: username} = _user
      ) do
    versions
    |> Enum.sort_by(& &1.version, :desc)
    |> Enum.find(%{}, &(&1.username == username))
    |> Map.get(:password)
  end
end

defmodule CommonCore.StateSummary.PostgresStateTest do
  use ExUnit.Case

  alias CommonCore.Batteries.BatteryCoreConfig
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Postgres.Cluster
  alias CommonCore.Postgres.PGUser
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.PostgresState

  test "read_write_hostname returns hostname when cluster found" do
    cl = %Cluster{name: "cluster1", type: :internal}

    state_summary = %StateSummary{
      postgres_clusters: [cl],
      batteries: [%SystemBattery{type: :battery_core, config: %BatteryCoreConfig{base_namespace: "battery-base"}}]
    }

    found_cluster = PostgresState.cluster(state_summary, name: "cluster1", type: :internal)
    assert cl == found_cluster

    assert PostgresState.read_write_hostname(state_summary, found_cluster) ==
             "pg-cluster1-rw.battery-base.svc.cluster.local."
  end

  describe "cluster/3" do
    test "cluster/3 returns cluster when found" do
      state_summary = %StateSummary{postgres_clusters: [%Cluster{name: "cluster1", type: :internal}]}

      assert PostgresState.cluster(state_summary, name: "cluster1", type: :internal) == %Cluster{
               name: "cluster1",
               type: :internal
             }
    end

    test "cluster/3 returns nil when not found" do
      state_summary = %StateSummary{
        postgres_clusters: [
          %Cluster{name: "other", type: :internal}
        ]
      }

      assert PostgresState.cluster(state_summary, name: "cluster1", type: :internal) == nil
    end
  end

  describe "user_secret/3" do
    test "returns default secret name if cluster is nil" do
      secret = PostgresState.user_secret(%{}, nil, %PGUser{username: "myuser"})
      assert secret == "cloudnative-pg.pg-unknown-cluster.unknown-user"
    end

    test "returns default secret name if user is nil" do
      cluster = %Cluster{name: "mycluster"}
      secret = PostgresState.user_secret(%{}, cluster, nil)
      assert secret == "cloudnative-pg.pg-unknown-cluster.unknown-user"
    end

    test "returns secret name joining cluster, username" do
      cluster = %Cluster{name: "mycluster"}
      user = %PGUser{username: "myuser"}
      secret = PostgresState.user_secret(%{}, cluster, user)
      assert secret == "cloudnative-pg.pg-mycluster.myuser"
    end
  end
end

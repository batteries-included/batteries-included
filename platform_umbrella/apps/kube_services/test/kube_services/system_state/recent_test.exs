defmodule KubeServices.SystemState.SummaryRecentTest do
  use ExUnit.Case, async: true

  alias CommonCore.Postgres.Cluster
  alias CommonCore.StateSummary
  alias Ecto.UUID
  alias KubeServices.SystemState.SummaryRecent

  require Logger

  setup do
    pid = start_supervised!({SummaryRecent, [name: SummaryRecentTestRecent, subscribe: false]})
    %{pid: pid}
  end

  describe "postgres_clusters" do
    test "returns empty list with no state", %{pid: pid} do
      assert SummaryRecent.postgres_clusters(pid) == []
    end

    test "Returns the latest n when asked", %{pid: pid} do
      now = DateTime.utc_now()

      clusters = [
        %Cluster{id: UUID.generate(), name: "cluster1", inserted_at: now, updated_at: now},
        %Cluster{
          id: UUID.generate(),
          name: "cluster2",
          inserted_at: Timex.shift(now, hours: -10),
          updated_at: Timex.shift(now, hours: -9)
        },
        %Cluster{
          id: UUID.generate(),
          name: "cluster3",
          inserted_at: Timex.shift(now, hours: -2),
          updated_at: Timex.shift(now, hours: -1)
        },
        %Cluster{
          id: UUID.generate(),
          name: "cluster4",
          inserted_at: Timex.shift(now, hours: -10),
          updated_at: Timex.shift(now, hours: -8)
        }
      ]

      send(pid, %StateSummary{postgres_clusters: clusters})

      # We should get them back in sorted order
      sorted = Enum.sort_by(clusters, & &1.updated_at, {:desc, DateTime})

      # We respect the limits
      assert sorted == SummaryRecent.postgres_clusters(pid)
      assert Enum.take(sorted, 2) == SummaryRecent.postgres_clusters(pid, 2)
    end
  end
end

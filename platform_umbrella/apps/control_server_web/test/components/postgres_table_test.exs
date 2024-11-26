defmodule ControlServerWeb.Components.PostgresClustersTableTest do
  use Heyya.SnapshotCase

  import ControlServer.Factory
  import ControlServerWeb.PostgresClusterTable

  describe "postgres_clusters_table" do
    component_snapshot_test "abbridgred" do
      assigns = %{
        clusters: [
          :postgres_cluster
          |> build(type: :standard, name: "cluster1")
          |> Map.put(:id, "00-00-00-00-00-00-00-00-00-00-01"),
          :postgres_cluster
          |> build(type: :internal, name: "cluster2")
          |> Map.put(:id, "00-00-00-00-00-00-00-00-00-00-02")
        ]
      }

      ~H"""
      <.postgres_clusters_table rows={@clusters} abridged />
      """
    end

    component_snapshot_test "unabbridged" do
      assigns = %{
        clusters: [
          :postgres_cluster
          |> build(type: :standard, name: "cluster1", num_instances: 3, virtual_size: "small")
          |> Map.put(:id, "00-00-00-00-00-00-00-00-00-00-03"),
          :postgres_cluster
          |> build(type: :internal, name: "cluster2", num_instances: 1, virtual_size: "huge")
          |> Map.put(:id, "00-00-00-00-00-00-00-00-00-00-04")
        ]
      }

      ~H"""
      <.postgres_clusters_table rows={@clusters} />
      """
    end
  end
end

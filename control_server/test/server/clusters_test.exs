defmodule Server.ClustersTest do
  use Server.DataCase

  alias Server.Clusters

  describe "kube_clusters" do
    alias Server.Clusters.KubeCluster

    @valid_attrs %{external_uid: "some external_uid"}
    @update_attrs %{external_uid: "some updated external_uid"}
    @invalid_attrs %{external_uid: nil}

    def kube_cluster_fixture(attrs \\ %{}) do
      {:ok, kube_cluster} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Clusters.create_kube_cluster()

      kube_cluster
    end

    test "list_kube_clusters/0 returns all kube_clusters" do
      kube_cluster = kube_cluster_fixture()
      assert Clusters.list_kube_clusters() == [kube_cluster]
    end

    test "get_kube_cluster!/1 returns the kube_cluster with given id" do
      kube_cluster = kube_cluster_fixture()
      assert Clusters.get_kube_cluster!(kube_cluster.id) == kube_cluster
    end

    test "create_kube_cluster/1 with valid data creates a kube_cluster" do
      assert {:ok, %KubeCluster{} = kube_cluster} = Clusters.create_kube_cluster(@valid_attrs)
      assert kube_cluster.external_uid == "some external_uid"
    end

    test "create_kube_cluster/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Clusters.create_kube_cluster(@invalid_attrs)
    end

    test "update_kube_cluster/2 with valid data updates the kube_cluster" do
      kube_cluster = kube_cluster_fixture()

      assert {:ok, %KubeCluster{} = kube_cluster} =
               Clusters.update_kube_cluster(kube_cluster, @update_attrs)

      assert kube_cluster.external_uid == "some updated external_uid"
    end

    test "update_kube_cluster/2 with invalid data returns error changeset" do
      kube_cluster = kube_cluster_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Clusters.update_kube_cluster(kube_cluster, @invalid_attrs)

      assert kube_cluster == Clusters.get_kube_cluster!(kube_cluster.id)
    end

    test "delete_kube_cluster/1 deletes the kube_cluster" do
      kube_cluster = kube_cluster_fixture()
      assert {:ok, %KubeCluster{}} = Clusters.delete_kube_cluster(kube_cluster)
      assert_raise Ecto.NoResultsError, fn -> Clusters.get_kube_cluster!(kube_cluster.id) end
    end

    test "change_kube_cluster/1 returns a kube_cluster changeset" do
      kube_cluster = kube_cluster_fixture()
      assert %Ecto.Changeset{} = Clusters.change_kube_cluster(kube_cluster)
    end
  end
end

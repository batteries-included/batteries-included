defmodule ControlServer.RookTest do
  use ControlServer.DataCase

  alias ControlServer.Rook

  describe "ceph_cluster" do
    alias ControlServer.Rook.CephCluster

    import ControlServer.Factory

    @invalid_attrs %{data_dir_host_path: nil, name: nil, nodes: nil, num_mgr: nil, num_mon: nil}

    setup do
      {:ok, ceph_cluster: insert(:ceph_cluster)}
    end

    test "list_ceph_cluster/0 returns all ceph_cluster", %{ceph_cluster: ceph_cluster} do
      assert Rook.list_ceph_cluster() == [ceph_cluster]
    end

    test "get_ceph_cluster!/1 returns the ceph_cluster with given id", %{
      ceph_cluster: ceph_cluster
    } do
      assert Rook.get_ceph_cluster!(ceph_cluster.id) == ceph_cluster
    end

    test "create_ceph_cluster/1 with valid data creates a ceph_cluster" do
      valid_attrs = %{
        data_dir_host_path: "some data_dir_host_path",
        name: "some name",
        nodes: [],
        num_mgr: 42,
        num_mon: 42
      }

      assert {:ok, %CephCluster{} = ceph_cluster} = Rook.create_ceph_cluster(valid_attrs)
      assert ceph_cluster.data_dir_host_path == "some data_dir_host_path"
      assert ceph_cluster.name == "some name"
      assert ceph_cluster.nodes == []
      assert ceph_cluster.num_mgr == 42
      assert ceph_cluster.num_mon == 42
    end

    test "create_ceph_cluster/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rook.create_ceph_cluster(@invalid_attrs)
    end

    test "update_ceph_cluster/2 with valid data updates the ceph_cluster", %{
      ceph_cluster: ceph_cluster
    } do
      update_attrs = %{
        data_dir_host_path: "some updated data_dir_host_path",
        name: "some updated name",
        nodes: [],
        num_mgr: 43,
        num_mon: 43
      }

      assert {:ok, %CephCluster{} = ceph_cluster} =
               Rook.update_ceph_cluster(ceph_cluster, update_attrs)

      assert ceph_cluster.data_dir_host_path == "some updated data_dir_host_path"
      assert ceph_cluster.name == "some updated name"
      assert ceph_cluster.nodes == []
      assert ceph_cluster.num_mgr == 43
      assert ceph_cluster.num_mon == 43
    end

    test "update_ceph_cluster/2 with invalid data returns error changeset" do
      ceph_cluster = insert(:ceph_cluster)
      assert {:error, %Ecto.Changeset{}} = Rook.update_ceph_cluster(ceph_cluster, @invalid_attrs)
      assert ceph_cluster == Rook.get_ceph_cluster!(ceph_cluster.id)
    end

    test "delete_ceph_cluster/1 deletes the ceph_cluster" do
      ceph_cluster = insert(:ceph_cluster)
      assert {:ok, %CephCluster{}} = Rook.delete_ceph_cluster(ceph_cluster)
      assert_raise Ecto.NoResultsError, fn -> Rook.get_ceph_cluster!(ceph_cluster.id) end
    end

    test "change_ceph_cluster/1 returns a ceph_cluster changeset", %{
      ceph_cluster: ceph_cluster
    } do
      assert %Ecto.Changeset{} = Rook.change_ceph_cluster(ceph_cluster)
    end
  end

  describe "ceph_filesystems" do
    alias ControlServer.Rook.CephFilesystem

    import ControlServer.Factory

    setup do
      {:ok, filesystem: insert(:ceph_filesystem), attrs: Map.from_struct(build(:ceph_filesystem))}
    end

    test "list_ceph_filesystem/0 returns all ceph filesystems", %{filesystem: fs} do
      assert Rook.list_ceph_filesystem() == [fs]
    end

    test "create_ceph_filesystem with valid data creates a ceph cluster", %{attrs: attrs} do
      assert {:ok, %CephFilesystem{} = ceph_filesystem} = Rook.create_ceph_filesystem(attrs)
      assert ceph_filesystem.name == attrs.name
      assert ceph_filesystem.include_erasure_encoded == attrs.include_erasure_encoded
    end

    test "update_ceph_filesystem/2 with valid data updates the ceph_filesystem", %{
      filesystem: fs,
      attrs: attrs
    } do
      assert {:ok, %CephFilesystem{} = updated_filesystem} =
               Rook.update_ceph_filesystem(fs, attrs)

      assert updated_filesystem.name == attrs.name
      assert updated_filesystem.include_erasure_encoded == attrs.include_erasure_encoded
    end
  end
end

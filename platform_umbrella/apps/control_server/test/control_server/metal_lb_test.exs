defmodule ControlServer.MetalLBTest do
  use ControlServer.DataCase

  alias CommonCore.MetalLB.IPAddressPool
  alias ControlServer.MetalLB

  describe "ip_address_pools" do
    import ControlServer.MetalLBFixtures

    @invalid_attrs %{name: nil, subnet: nil}

    test "list_ip_address_pools/0 returns all ip address pools" do
      ip_address_pool = ip_address_pool_fixture()
      assert MetalLB.list_ip_address_pools() == [ip_address_pool]
    end

    test "list_ip_address_pools/1 returns paginated ip address pools" do
      ip_address_pool1 = ip_address_pool_fixture()
      _ip_address_pool2 = ip_address_pool_fixture()

      assert {:ok, {[ip_address_pool], _}} = MetalLB.list_ip_address_pools(%{limit: 1})
      assert ip_address_pool.id == ip_address_pool1.id
    end

    test "get_ip_address_pool!/1 returns the ip_address_pool with given id" do
      ip_address_pool = ip_address_pool_fixture()
      assert MetalLB.get_ip_address_pool!(ip_address_pool.id) == ip_address_pool
    end

    test "create_ip_address_pool/1 with valid data creates a ip_address_pool" do
      valid_attrs = %{name: "some-name", subnet: "some subnet"}

      assert {:ok, %IPAddressPool{} = ip_address_pool} =
               MetalLB.create_ip_address_pool(valid_attrs)

      assert ip_address_pool.name == "some-name"
      assert ip_address_pool.subnet == "some subnet"
    end

    test "create_ip_address_pool/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = MetalLB.create_ip_address_pool(@invalid_attrs)
    end

    test "update_ip_address_pool/2 with valid data updates the ip_address_pool" do
      ip_address_pool = ip_address_pool_fixture()
      update_attrs = %{subnet: "some updated subnet"}

      assert {:ok, %IPAddressPool{} = ip_address_pool} =
               MetalLB.update_ip_address_pool(ip_address_pool, update_attrs)

      assert ip_address_pool.subnet == "some updated subnet"
    end

    test "update_ip_address_pool/2 with invalid data returns error changeset" do
      ip_address_pool = ip_address_pool_fixture()

      assert {:error, %Ecto.Changeset{}} =
               MetalLB.update_ip_address_pool(ip_address_pool, @invalid_attrs)

      assert ip_address_pool == MetalLB.get_ip_address_pool!(ip_address_pool.id)
    end

    test "delete_ip_address_pool/1 deletes the ip_address_pool" do
      ip_address_pool = ip_address_pool_fixture()
      assert {:ok, %IPAddressPool{}} = MetalLB.delete_ip_address_pool(ip_address_pool)
      assert_raise Ecto.NoResultsError, fn -> MetalLB.get_ip_address_pool!(ip_address_pool.id) end
    end

    test "change_ip_address_pool/1 returns a ip_address_pool changeset" do
      ip_address_pool = ip_address_pool_fixture()
      assert %Ecto.Changeset{} = MetalLB.change_ip_address_pool(ip_address_pool)
    end
  end
end

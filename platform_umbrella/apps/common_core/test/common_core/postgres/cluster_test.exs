defmodule CommonCore.Postgres.ClusterTest do
  use ExUnit.Case

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Util.Memory
  alias Ecto.Changeset

  describe "changeset/2" do
    setup do
      %{
        valid_attrs: %{
          name: "test",
          storage_size: 137_438_953_472,
          num_instances: 1,
          type: :standard
        }
      }
    end

    test "creates a valid changeset", %{valid_attrs: valid_attrs} do
      changeset = Cluster.changeset(%Cluster{}, valid_attrs)
      assert changeset.valid?
    end

    test "creates an invalid changeset when missing required fields" do
      changeset = Cluster.changeset(%Cluster{}, %{name: nil, storage_size: nil, num_instances: nil, type: nil})
      refute changeset.valid?
    end

    test "validates the length of the name", %{valid_attrs: valid_attrs} do
      changeset =
        Cluster.changeset(
          %Cluster{},
          Map.put(
            valid_attrs,
            :name,
            "this name is too long this name is too long this" <>
              "name is too long this name is too long really really" <>
              "really really long like super long and i dont know why"
          )
        )

      refute changeset.valid?
    end
  end

  describe "put_storage_size/2" do
    setup do
      %{changeset: Cluster.changeset(%Cluster{}, %{})}
    end

    test "should put a storage size into the changeset", %{changeset: changeset} do
      bytes = 1 |> Memory.to_bytes(:TB) |> to_string()
      changeset = Cluster.put_storage_size(changeset, bytes)

      assert Changeset.get_change(changeset, :storage_size) == Memory.to_bytes(375, :GB)
    end

    test "should return error for non-parsable value", %{changeset: changeset} do
      assert %Changeset{valid?: false} = Cluster.put_storage_size(changeset, "foo")
    end
  end

  describe "put_range_from_storage_size/2" do
    test "should put a range value from the storage size" do
      changeset = Cluster.changeset(%Cluster{}, %{storage_size: Memory.to_bytes(375, :GB)})
      changeset = Cluster.put_range_from_storage_size(changeset)

      assert Changeset.get_change(changeset, :virtual_storage_size_range_value) == Memory.to_bytes(1, :TB)
    end

    test "should put a range value of 0 when there is no storage size" do
      changeset = Cluster.changeset(%Cluster{}, %{})
      changeset = Cluster.put_range_from_storage_size(changeset)

      assert Changeset.get_change(changeset, :virtual_storage_size_range_value) == 0
    end
  end
end

defmodule CommonCore.Postgres.ClusterTest do
  use ExUnit.Case

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Util.Memory
  alias Ecto.Changeset

  describe "changeset/3" do
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
      assert %{valid?: true} = Cluster.changeset(%Cluster{}, valid_attrs)
    end

    test "creates an invalid changeset when missing required fields" do
      assert %{valid?: false} =
               Cluster.changeset(%Cluster{}, %{name: nil, storage_size: nil, num_instances: nil, type: nil})
    end

    test "validates the length of the name", %{valid_attrs: valid_attrs} do
      assert %{valid?: false} =
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
    end

    test "should put a range value from the storage size" do
      assert %Cluster{}
             |> Cluster.changeset(%{storage_size: Memory.to_bytes(375, :GB)})
             |> Changeset.get_change(:virtual_storage_size_range_value) == Memory.to_bytes(1, :TB)
    end

    test "should put a range value of 0 when there is no storage size" do
      assert %Cluster{}
             |> Cluster.changeset(%{})
             |> Changeset.get_change(:virtual_storage_size_range_value) == 0
    end

    test "should put a storage size into the changeset with ticks" do
      assert %Cluster{}
             |> Cluster.changeset(%{storage_size: Memory.to_bytes(50, :GB)},
               range_ticks: Cluster.compact_storage_range_ticks()
             )
             |> Changeset.get_change(:virtual_storage_size_range_value) == Memory.to_bytes(0.3, :TB)
    end

    test "should return error for decreased storage size" do
      assert %{valid?: false} = Cluster.changeset(%Cluster{storage_size: Memory.to_bytes(1, :TB)}, %{storage_size: 1})
    end
  end

  describe "put_storage_size/3" do
    setup do
      %{changeset: Cluster.changeset(%Cluster{}, %{})}
    end

    test "should put a storage size into the changeset", %{changeset: changeset} do
      assert changeset
             |> Cluster.put_storage_size(1 |> Memory.to_bytes(:TB) |> to_string())
             |> Changeset.get_change(:storage_size) == Memory.to_bytes(375, :GB)
    end

    test "should put a storage size into the changeset with ticks", %{changeset: changeset} do
      assert changeset
             |> Cluster.put_storage_size(
               0.3 |> Memory.to_bytes(:TB) |> to_string(),
               Cluster.compact_storage_range_ticks()
             )
             |> Changeset.get_change(:storage_size) == Memory.to_bytes(50, :GB)
    end

    test "should return error for decreased storage size" do
      assert %{valid?: false} =
               %Cluster{storage_size: Memory.to_bytes(1, :TB)}
               |> Cluster.changeset(%{})
               |> Cluster.put_storage_size(1)
    end

    test "should return error for non-parsable value", %{changeset: changeset} do
      assert %{valid?: false} = Cluster.put_storage_size(changeset, "foo")
    end
  end
end

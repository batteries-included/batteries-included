defmodule CommonCore.Postgres.ClusterTest do
  use ExUnit.Case

  alias CommonCore.Postgres.Cluster
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
      changeset = Cluster.changeset(%Cluster{}, %{})
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

  describe "validate/1" do
    test "returns a valid changeset and struct with valid attributes" do
      attrs = %{
        name: "test",
        storage_size: 137_438_953_472,
        num_instances: 1,
        type: :standard
      }

      {changeset, _data} = Cluster.validate(attrs)
      assert changeset.valid?
    end

    test "returns an invalid changeset with invalid attributes" do
      attrs = %{}

      {changeset, _data} = Cluster.validate(attrs)
      refute changeset.valid?
    end
  end

  describe "to_fresh_cluster/1" do
    test "creates a new cluster with valid attributes" do
      attrs = %{
        name: "test",
        storage_size: 137_438_953_472,
        num_instances: 1,
        type: :standard
      }

      cluster = Cluster.to_fresh_cluster(attrs)
      assert cluster.name == attrs.name
    end
  end

  describe "convert_virtual_size_to_presets/1" do
    test "sets the appropriate presets for small size" do
      virtual_size = "small"
      changeset = Cluster.changeset(%Cluster{}, %{virtual_size: virtual_size})
      storage_size_preset_value = Cluster.get_preset(virtual_size).storage_size
      assert storage_size_preset_value == Changeset.get_field(changeset, :storage_size)
    end
  end
end

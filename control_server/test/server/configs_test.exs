defmodule Server.ConfigsTest do
  use Server.DataCase

  alias Server.Configs
  import Server.Factory

  describe "raw_configs" do
    alias Server.Configs.RawConfig

    @update_attrs %{content: %{}, path: "some updated path"}
    @invalid_attrs %{content: nil, path: nil}

    test "list_raw_configs/0 returns all raw_configs" do
      raw_config = insert(:raw_config)
      %RawConfig{id: id} = raw_config
      assert Enum.any?(Configs.list_raw_configs(), fn x -> x.id == id end)
    end

    test "get_raw_config!/1 returns the raw_config with given id" do
      raw_config = insert(:raw_config)

      assert raw_config == Configs.get_raw_config!(raw_config.id)
    end

    test "update_raw_config/2 with valid data updates the raw_config" do
      raw_config = insert(:raw_config)

      assert {:ok, %RawConfig{} = raw_config} =
               Configs.update_raw_config(raw_config, @update_attrs)

      assert raw_config.content == %{}
      assert raw_config.path == "some updated path"
    end

    test "update_raw_config/2 with invalid data returns error changeset" do
      raw_config = insert(:raw_config)
      assert {:error, %Ecto.Changeset{}} = Configs.update_raw_config(raw_config, @invalid_attrs)

      assert raw_config == Configs.get_raw_config!(raw_config.id)
    end

    test "delete_raw_config/1 deletes the raw_config" do
      raw_config = insert(:raw_config)
      assert {:ok, %RawConfig{}} = Configs.delete_raw_config(raw_config)
      assert_raise Ecto.NoResultsError, fn -> Configs.get_raw_config!(raw_config.id) end
    end

    test "change_raw_config/1 returns a raw_config changeset" do
      raw_config = insert(:raw_config)
      assert %Ecto.Changeset{} = Configs.change_raw_config(raw_config)
    end
  end
end

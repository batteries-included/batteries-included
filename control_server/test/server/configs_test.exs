defmodule Server.ConfigsTest do
  use Server.DataCase

  alias Server.Configs

  describe "raw_configs" do
    alias Server.Configs.RawConfig

    @valid_attrs %{content: %{}, path: "some path"}
    @update_attrs %{content: %{}, path: "some updated path"}
    @invalid_attrs %{content: nil, path: nil}

    def raw_config_fixture(attrs \\ %{}) do
      {:ok, raw_config} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Configs.create_raw_config()

      raw_config
    end

    test "list_raw_configs/0 returns all raw_configs" do
      raw_config = raw_config_fixture()
      assert Configs.list_raw_configs() == [raw_config]
    end

    test "get_raw_config!/1 returns the raw_config with given id" do
      raw_config = raw_config_fixture()
      assert Configs.get_raw_config!(raw_config.id) == raw_config
    end

    test "create_raw_config/1 with valid data creates a raw_config" do
      assert {:ok, %RawConfig{} = raw_config} = Configs.create_raw_config(@valid_attrs)
      assert raw_config.content == %{}
      assert raw_config.path == "some path"
    end

    test "create_raw_config/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Configs.create_raw_config(@invalid_attrs)
    end

    test "update_raw_config/2 with valid data updates the raw_config" do
      raw_config = raw_config_fixture()

      assert {:ok, %RawConfig{} = raw_config} =
               Configs.update_raw_config(raw_config, @update_attrs)

      assert raw_config.content == %{}
      assert raw_config.path == "some updated path"
    end

    test "update_raw_config/2 with invalid data returns error changeset" do
      raw_config = raw_config_fixture()
      assert {:error, %Ecto.Changeset{}} = Configs.update_raw_config(raw_config, @invalid_attrs)
      assert raw_config == Configs.get_raw_config!(raw_config.id)
    end

    test "delete_raw_config/1 deletes the raw_config" do
      raw_config = raw_config_fixture()
      assert {:ok, %RawConfig{}} = Configs.delete_raw_config(raw_config)
      assert_raise Ecto.NoResultsError, fn -> Configs.get_raw_config!(raw_config.id) end
    end

    test "change_raw_config/1 returns a raw_config changeset" do
      raw_config = raw_config_fixture()
      assert %Ecto.Changeset{} = Configs.change_raw_config(raw_config)
    end
  end
end

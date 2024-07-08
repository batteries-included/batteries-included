defmodule CommonCore.VersionTest do
  use ExUnit.Case

  describe "CommonCore.Version.version/1" do
    test "version isn't nil" do
      assert CommonCore.Version.version() != nil
    end

    test "version is the correct length" do
      assert String.length(CommonCore.Version.version()) == 6
    end

    test "version can be parsed by Elixir.Version" do
      assert {:ok, _} = Version.parse(CommonCore.Version.version())
    end
  end

  describe "CommonCore.Version.hash/1" do
    test "hash isnt nil" do
      assert CommonCore.Version.hash() != nil
    end

    test "hash is the correct length" do
      assert String.length(CommonCore.Version.hash()) >= 5
    end
  end
end

defmodule CommonCore.VersionTest do
  use ExUnit.Case

  describe "CommonCore.Version.version/1" do
    test "version is the correct length" do
      # 1.0.0 is 5 characters long
      # 0.27.0 is 6 characters long
      assert String.length(CommonCore.Version.version()) >= 5
    end

    test "version can be parsed by Elixir.Version" do
      assert {:ok, _} = Version.parse(CommonCore.Version.version())
    end
  end

  describe "CommonCore.Version.hash/1" do
    test "hash is the correct length" do
      assert String.length(CommonCore.Version.hash()) >= 5
    end
  end

  describe "CommonCore.Version.compare_version/2" do
    test "compare_version/2 returns {:ok, :equal} when versions are equal" do
      assert CommonCore.Version.compare("1.2.3", "1.2.3") == {:ok, :equal}
    end

    test "compare_version/2 returns {:ok, :lesser} when for version with hashes" do
      assert CommonCore.Version.compare("1.2.3-deadbeef", "1.2.4-aaaa") == {:ok, :lesser}
    end

    test "compare_version/2 returns {:ok, :greater} when first version is greater in last place" do
      assert CommonCore.Version.compare("1.2.4", "1.2.3") == {:ok, :greater}
    end

    test "compare_version/2 returns {:error, :incomparable} when an invalid version is used" do
      assert CommonCore.Version.compare("1.2.4", "jdt-test") == {:error, :incomparable}
      assert CommonCore.Version.compare("jdt-test", "1.2.3") == {:error, :incomparable}
    end
  end
end

defmodule Server.Configs.ComputedConfigsTest do
  use Server.DataCase

  alias Server.ComputedConfigs

  test "get" do
    {:ok, config} = ComputedConfigs.get("/prometheus/main")
    assert config.path == "/prometheus/main"
  end
end

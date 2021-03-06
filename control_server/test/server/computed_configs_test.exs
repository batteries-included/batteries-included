defmodule Server.Configs.ComputedConfigsTest do
  use Server.DataCase

  alias Server.ComputedConfigs
  alias Server.Configs.Defaults

  test "get" do
    {:ok, _} = Defaults.create_all()

    {:ok, config} = ComputedConfigs.get("/prometheus/main")
    assert config.path == "/prometheus/main"
  end
end

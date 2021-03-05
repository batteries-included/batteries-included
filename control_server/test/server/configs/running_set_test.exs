defmodule Server.Configs.DefaultsTest do
  use Server.DataCase

  import Server.Factory
  alias Server.Configs.RawConfig
  alias Server.Configs.RunningSet

  test "create_running_set" do
    {:ok, %RawConfig{} = raw_config} = RunningSet.create()
    assert raw_config.content == %{"monitoring" => false}
    assert raw_config.path == "/running_set"
  end
end

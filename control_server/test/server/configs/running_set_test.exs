defmodule Server.Configs.DefaultsTest do
  use Server.DataCase

  alias Server.Configs
  alias Server.Configs.RawConfig
  alias Server.Configs.RunningSet

  test "create_running_set" do
    %RawConfig{} = raw_config = Configs.get_by_path!("/running_set")
    assert raw_config.content == %{"monitoring" => false}
    assert raw_config.path == "/running_set"
  end

  test "set running" do
    rc = Configs.get_by_path!("/running_set")
    %RawConfig{} = RunningSet.set_running(rc, "monitoring")
  end
end

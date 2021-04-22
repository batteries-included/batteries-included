defmodule ControlServer.Configs.DefaultsTest do
  use ControlServer.DataCase

  alias ControlServer.Configs
  alias ControlServer.Configs.RawConfig
  alias ControlServer.Configs.RunningSet

  test "create_running_set" do
    %RawConfig{} = raw_config = Configs.get_by_path!("/running_set")
    assert raw_config.content == %{"monitoring" => false}
    assert raw_config.path == "/running_set"
  end

  test "set running" do
    rc = Configs.get_by_path!("/running_set")
    assert {:ok, %RawConfig{}} = RunningSet.set_running(rc, "monitoring", true)
  end
end

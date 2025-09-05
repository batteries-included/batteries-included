defmodule KubeServices.Stale.StaleResourceWatcherTest do
  use ExUnit.Case

  import Mox

  setup :verify_on_exit!

  test "StaleResourceWatcher starts successfully" do
    assert {:ok, _pid} = KubeServices.Stale.Watcher.start_link(delay: 1000)
  end
end

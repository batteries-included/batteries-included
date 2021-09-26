defmodule KubeResources.DevtoolsTest do
  use ControlServer.DataCase

  alias KubeResources.Devtools

  test "Can materialize" do
    assert map_size(Devtools.materialize(%{})) >= 5
  end
end

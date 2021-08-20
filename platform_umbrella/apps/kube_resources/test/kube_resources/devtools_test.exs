defmodule KubeResources.DevtoolsTest do
  use ControlServer.DataCase, async: true

  alias KubeResources.Devtools

  test "Can materialize" do
    assert map_size(Devtools.materialize(%{})) >= 5
  end
end

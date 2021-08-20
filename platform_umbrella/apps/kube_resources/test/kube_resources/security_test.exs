defmodule KubeResources.SecurityTest do
  use ControlServer.DataCase, async: true

  alias KubeResources.Security

  test "Can materialize" do
    assert map_size(Security.materialize(%{})) >= 5
  end
end

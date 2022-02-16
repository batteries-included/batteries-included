defmodule KubeResources.SecurityTest do
  use ControlServer.DataCase

  alias KubeResources.CertManager

  test "Can materialize" do
    assert map_size(CertManager.materialize(%{})) >= 5
  end
end

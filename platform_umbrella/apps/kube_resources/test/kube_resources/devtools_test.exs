defmodule KubeResources.DevtoolsTest do
  use ControlServer.DataCase

  alias KubeResources.KnativeOperator

  test "Can materialize knative operator" do
    assert map_size(KnativeOperator.materialize(%{})) >= 5
  end
end

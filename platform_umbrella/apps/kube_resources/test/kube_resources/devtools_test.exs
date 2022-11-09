defmodule KubeResources.DevtoolsTest do
  use ExUnit.Case

  alias KubeResources.KnativeOperator

  test "Can materialize knative operator" do
    assert map_size(KnativeOperator.materialize(%{config: %{}}, %{})) >= 5
  end
end

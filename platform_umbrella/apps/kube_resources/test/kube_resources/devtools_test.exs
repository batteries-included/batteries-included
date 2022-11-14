defmodule KubeResources.DevtoolsTest do
  use ExUnit.Case

  alias KubeResources.KnativeOperator
  alias KubeExt.SystemState.StateSummary

  test "Can materialize knative operator" do
    assert map_size(KnativeOperator.materialize(%{config: %{}}, %StateSummary{})) >= 5
  end
end

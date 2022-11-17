defmodule KubeResources.DevtoolsTest do
  use ExUnit.Case

  alias KubeResources.KnativeOperator
  alias KubeExt.SystemState.StateSummary
  alias KubeExt.Defaults.Images

  test "Can materialize knative operator" do
    assert map_size(KnativeOperator.materialize(knative_operator_battery(), %StateSummary{})) >= 5
  end

  def knative_operator_battery do
    %{
      type: :knative_operator,
      config: %{
        operator_image: Images.knative_operator_image(),
        webhook_image: Images.knative_operator_webhook_image()
      }
    }
  end
end

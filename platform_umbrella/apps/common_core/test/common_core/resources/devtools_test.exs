defmodule CommonCore.Resources.DevtoolsTest do
  use ExUnit.Case

  alias CommonCore.Defaults.Images
  alias CommonCore.Resources.KnativeOperator
  alias CommonCore.StateSummary

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

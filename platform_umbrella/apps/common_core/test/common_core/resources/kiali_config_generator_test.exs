defmodule CommonCore.Resources.Istio.KialiConfigGeneratorTest do
  use ExUnit.Case

  alias CommonCore.Resources.Istio.KialiConfigGenerator
  alias CommonCore.StateSummary

  describe "materialize/2" do
    test "sets namespaces from state" do
      state = %StateSummary{batteries: []}

      config = KialiConfigGenerator.materialize(:test_battery, state)
      assert config["istio_namespace"] == nil
    end
  end
end

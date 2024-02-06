defmodule CommonCore.StateSummary.BatteriesTest do
  use ExUnit.Case

  import CommonCore.StateSummary.Batteries

  alias CommonCore.StateSummary

  describe "batteries_installed?/2" do
    test "returns true if all battery types are installed" do
      state = %StateSummary{batteries: [%{type: :postgres}, %{type: :redis}]}
      assert batteries_installed?(state, [:postgres, :redis])
    end

    test "returns false if any battery type is not installed" do
      state = %StateSummary{batteries: [%{type: :postgres}]}
      refute batteries_installed?(state, [:postgres, :redis])
    end
  end

  describe "sso_installed?/1" do
    test "returns true if sso is installed" do
      state = %StateSummary{batteries: [%{type: :sso}]}
      assert sso_installed?(state)
    end

    test "returns false if sso is not installed" do
      state = %StateSummary{batteries: [%{type: :postgres}]}
      refute sso_installed?(state)
    end
  end
end

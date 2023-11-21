defmodule CommonCore.Resources.FilterResourceTest do
  use ExUnit.Case

  alias CommonCore.Resources.FilterResource

  describe "batteries_installed?/2" do
    test "returns true if all battery types are installed" do
      state = %{batteries: [%{type: :postgres}, %{type: :redis}]}
      assert FilterResource.batteries_installed?(state, [:postgres, :redis])
    end

    test "returns false if any battery type is not installed" do
      state = %{batteries: [%{type: :postgres}]}
      refute FilterResource.batteries_installed?(state, [:postgres, :redis])
    end
  end

  describe "sso_installed?/1" do
    test "returns true if sso is installed" do
      state = %{batteries: [%{type: :sso}]}
      assert FilterResource.sso_installed?(state)
    end

    test "returns false if sso is not installed" do
      state = %{batteries: [%{type: :postgres}]}
      refute FilterResource.sso_installed?(state)
    end
  end
end

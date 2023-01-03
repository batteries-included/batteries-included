defmodule KubeResources.BatteryTest do
  use ExUnit.Case

  alias KubeResources.ControlServer, as: ControlServerResources
  alias CommonCore.SystemState.StateSummary
  alias CommonCore.Defaults

  describe "Battery core services works" do
    test "Can materialize control server" do
      assert map_size(ControlServerResources.materialize(control_battery(), %StateSummary{})) >= 2
    end
  end

  defp control_battery do
    %{
      config: %{
        image: Defaults.Images.control_server_image(),
        secret_key: Defaults.random_key_string()
      }
    }
  end
end

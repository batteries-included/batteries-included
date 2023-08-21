defmodule CommonCore.Resources.BatteryTest do
  use ExUnit.Case

  alias CommonCore.Defaults
  alias CommonCore.Resources.ControlServer, as: ControlServerResources
  alias CommonCore.StateSummary

  describe "Battery core services works" do
    test "Can materialize control server" do
      assert map_size(ControlServerResources.materialize(control_battery(), %StateSummary{})) >= 2
    end
  end

  defp control_battery do
    %{
      config: %{
        image: Defaults.Images.control_server_image(),
        secret_key: Defaults.random_key_string(),
        server_in_cluster: true
      }
    }
  end
end

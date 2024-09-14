defmodule CommonCore.Resources.BatteryTest do
  use ExUnit.Case

  alias CommonCore.Batteries.BatteryCoreConfig
  alias CommonCore.Batteries.CloudnativePGConfig
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Defaults
  alias CommonCore.Postgres.Cluster
  alias CommonCore.Postgres.PGUser
  alias CommonCore.Resources.ControlServer, as: ControlServerResources
  alias CommonCore.StateSummary

  describe "Battery core services works" do
    test "Can materialize control server" do
      cb = control_battery()
      cnb = cloudnative_battery()
      clusters = clusters()

      assert map_size(
               ControlServerResources.materialize(control_battery(), %StateSummary{
                 batteries: [cb, cnb],
                 postgres_clusters: clusters
               })
             ) >= 2
    end
  end

  defp control_battery do
    %SystemBattery{
      config: %BatteryCoreConfig{
        secret_key: Defaults.random_key_string()
      },
      type: :battery_core
    }
  end

  defp cloudnative_battery do
    %SystemBattery{
      type: :cloudnative_pg,
      config: %CloudnativePGConfig{}
    }
  end

  defp clusters do
    [
      %Cluster{
        name: Defaults.ControlDB.cluster_name(),
        type: :internal,
        users: [%PGUser{username: Defaults.ControlDB.user_name()}]
      }
    ]
  end
end

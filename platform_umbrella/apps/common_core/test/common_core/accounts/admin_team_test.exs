defmodule CommonCore.AdminTeamTest do
  use ExUnit.Case, async: false

  import Mox

  alias CommonCore.Accounts.AdminTeams
  alias CommonCore.Accounts.EnvFetcherMock
  alias CommonCore.Ecto.BatteryUUID

  describe "admin_team_ids/0" do
    test "returns the expected development admin team ids" do
      assert AdminTeams.admin_team_ids() == [AdminTeams.bootstrap_team().id]
    end
  end

  describe "using env" do
    setup :verify_on_exit!

    setup do
      old_env = Application.get_env(:common_core, AdminTeams, [])
      new_env = Keyword.put(old_env, :env_fetcher, EnvFetcherMock)

      Application.put_env(:common_core, AdminTeams, new_env)
      on_exit(fn -> Application.put_env(:common_core, AdminTeams, old_env) end)
    end

    test "includes the environment team ids" do
      id = "batt_ca695f31d27c44159d9e079ccb37d9f7"
      {:ok, battery_id} = BatteryUUID.cast(id)
      expect(EnvFetcherMock, :get_env, fn -> id end)
      assert AdminTeams.admin_team_ids() == [battery_id, AdminTeams.bootstrap_team().id]
    end
  end
end

defmodule HomeBase.Accounts.AdminTeams.DefaultEnvFetcher do
  @moduledoc false
  @behaviour HomeBase.Accounts.AdminTeams.EnvFetcher

  @key "BATTERY_TEAM_IDS"
  @spec get_env() :: String.t()
  def get_env, do: System.get_env(key(), "")

  @spec key() :: String.t()
  def key, do: @key
end

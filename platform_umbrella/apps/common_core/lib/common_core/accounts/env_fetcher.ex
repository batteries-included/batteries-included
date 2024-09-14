defmodule CommonCore.Accounts.EnvFetcher do
  @moduledoc false
  alias CommonCore.Accounts.DefaultEnvFetcher

  @callback get_env() :: String.t()
  @callback key() :: String.t()

  def impl do
    :common_core
    |> Application.get_env(CommonCore.Accounts.AdminTeams, [])
    |> Keyword.get(:env_fetcher, DefaultEnvFetcher)
  end

  def get_env do
    impl().get_env()
  end

  def key do
    impl().key()
  end
end

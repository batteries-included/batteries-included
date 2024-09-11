defmodule HomeBase.Accounts.AdminTeams.EnvFetcher do
  @moduledoc false
  alias HomeBase.Accounts.AdminTeams.DefaultEnvFetcher

  @callback get_env() :: String.t()
  @callback key() :: String.t()

  def impl do
    :home_base
    |> Application.get_env(HomeBase.Accounts.AdminTeams, [])
    |> Keyword.get(:env_fetcher, DefaultEnvFetcher)
  end

  def get_env do
    impl().get_env()
  end

  def key do
    impl().key()
  end
end

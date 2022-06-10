defmodule ControlServerWeb.IntegrationTestCase do
  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      use ExUnit.Case, async: false
      use Wallaby.Feature

      import Wallaby.Query
    end
  end

  setup do
    :ok = Sandbox.checkout(ControlServer.Repo, ownership_timeout: 300_000)
    Sandbox.mode(ControlServer.Repo, {:shared, self()})
    :ok
  end
end

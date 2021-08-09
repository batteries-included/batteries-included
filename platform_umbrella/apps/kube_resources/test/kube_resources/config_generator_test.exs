defmodule KubeServices.ConfigGeneratorTest do
  use ExUnit.Case

  alias KubeResources.ConfigGenerator
  alias ControlServer.Services
  alias ControlServer.Services.Monitoring
  alias ControlServer.Services.Database
  alias ControlServer.Services.Security

  describe "ConfigGenerator" do
    setup do
      # Explicitly get a connection before each test
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(ControlServer.Repo)

      {:ok,
       monitoring: Monitoring.activate!(),
       database: Database.activate!(),
       security: Security.activate!()}
    end

    test "materialize all the configs" do
      Services.list_base_services()
      |> Enum.each(fn service ->
        configs = ConfigGenerator.materialize(service)

        assert map_size(configs) >= 10
      end)
    end
  end
end

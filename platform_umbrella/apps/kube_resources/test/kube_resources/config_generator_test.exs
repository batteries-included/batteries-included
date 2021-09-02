defmodule KubeServices.ConfigGeneratorTest do
  use ControlServer.DataCase, async: true

  alias KubeResources.ConfigGenerator
  alias ControlServer.Services
  alias ControlServer.Services.Monitoring
  alias ControlServer.Services.Database
  alias ControlServer.Services.Security

  require Logger

  describe "ConfigGenerator" do
    setup do
      {:ok,
       monitoring: Monitoring.activate!(),
       database: Database.activate!(),
       security: Security.activate!()}
    end

    test "materialize all the configs" do
      Services.list_base_services()
      |> Enum.each(fn service ->
        Logger.warning("Materialize #{inspect(service)}")
        configs = ConfigGenerator.materialize(service)

        assert map_size(configs) >= 1
      end)
    end
  end
end

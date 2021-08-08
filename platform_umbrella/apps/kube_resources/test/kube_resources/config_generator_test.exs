defmodule KubeServices.ConfigGeneratorTest do
  use ControlServer.DataCase

  alias KubeResources.ConfigGenerator
  alias ControlServer.Services
  alias ControlServer.Services.Monitoring
  alias ControlServer.Services.Database
  alias ControlServer.Services.Security

  describe "ConfigGenerator" do
    test "materialize all the configs" do
      Monitoring.activate!()
      Database.activate!()
      Security.activate!()

      Services.list_base_services()
      |> Enum.each(fn service ->
        configs = ConfigGenerator.materialize(service)

        assert map_size(configs) >= 10
      end)
    end
  end
end

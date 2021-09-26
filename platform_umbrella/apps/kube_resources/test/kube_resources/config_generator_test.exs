defmodule KubeServices.ConfigGeneratorTest do
  use ControlServer.DataCase

  alias KubeResources.ConfigGenerator
  alias ControlServer.Services
  alias ControlServer.Services.Monitoring
  alias ControlServer.Services.ML
  alias ControlServer.Services.Database
  alias ControlServer.Services.Security

  require Logger

  describe "ConfigGenerator" do
    setup do
      {:ok,
       monitoring: Monitoring.activate!(),
       ml: ML.activate!(),
       database: Database.activate!(),
       security: Security.activate!()}
    end

    test "materialize all the configs" do
      Services.list_base_services()
      |> Enum.each(fn service ->
        configs = ConfigGenerator.materialize(service)

        assert map_size(configs) >= 1
      end)
    end

    test "everything can turn into json" do
      Services.list_base_services()
      |> Enum.each(fn base_service ->
        configs = ConfigGenerator.materialize(base_service)

        {res, _value} = Jason.encode(configs)

        assert :ok == res
      end)
    end
  end
end

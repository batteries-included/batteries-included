defmodule ControlServer.Services.ConfigGeneratorTest do
  use ControlServer.DataCase

  alias ControlServer.ConfigGenerator
  alias ControlServer.Services
  alias ControlServer.Services.Monitoring

  describe "ConfigGenerator" do
    test "materialize all the configs" do
      Monitoring.activate()

      Services.list_base_services()
      |> Enum.each(fn service ->
        configs = ConfigGenerator.materialize(service)

        assert map_size(configs) > 20
      end)
    end
  end

  test "doesn't monitor deactivated services" do
    Monitoring.activate()
    Monitoring.deactivate()

    Services.list_base_services()
    |> Enum.each(fn service ->
      configs = ConfigGenerator.materialize(service)

      assert map_size(configs) == 0
    end)
  end
end

defmodule ControlServer.Services.MonitoringTest do
  use ControlServer.DataCase

  alias ControlServer.Services.Monitoring
  alias K8s.Client

  describe "Services.Monitoring should generate good configs" do
    test "Materializing the default config" do
      config_map = Monitoring.materialize(Monitoring.default_config())

      config_map
      |> Enum.each(fn {_path, resource} ->
        operation = Client.create(resource)
        assert Map.get(operation.data, "metadata") == Map.get(resource, "metadata")
      end)
    end
  end

  test "Activate and Deactivate" do
    assert Monitoring.active?() == false

    Monitoring.activate()

    assert Monitoring.active?()
  end
end

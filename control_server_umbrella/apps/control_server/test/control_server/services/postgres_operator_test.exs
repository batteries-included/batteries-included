defmodule ControlServer.Services.PostgresOperatorTest do
  use ControlServer.DataCase

  alias ControlServer.Services.Database
  alias K8s.Client

  describe "PostgresOperator" do
    test "Materializing the default config" do
      config_map = Database.materialize(Database.default_config())

      config_map
      |> Enum.each(fn {_path, resource} ->
        operation = Client.create(resource)
        assert Map.get(operation.data, "metadata") == Map.get(resource, "metadata")
      end)
    end
  end
end

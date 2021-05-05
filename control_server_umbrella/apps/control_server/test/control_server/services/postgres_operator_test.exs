defmodule ControlServer.Services.PostgresOperatorTest do
  use ControlServer.DataCase

  alias ControlServer.Services.Database

  describe "PostgresOperator" do
    test "Materializing the default config" do
      config_map = Database.materialize(Database.default_config())
      assert_config_map_good(config_map)
    end
  end
end

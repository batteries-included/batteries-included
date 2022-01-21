defmodule ControlServer.Services.DatabaseTest do
  use ControlServer.DataCase

  alias ControlServer.Services.Database
  alias ControlServer.Release

  describe "Database" do
    test "Database is a default enabled service." do
      assert Database.active?() == false
      Release.seed()

      assert Database.active?() == true
    end
  end
end

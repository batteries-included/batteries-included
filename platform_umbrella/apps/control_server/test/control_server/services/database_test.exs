defmodule ControlServer.Services.DatabaseTest do
  use ControlServer.DataCase

  alias ControlServer.Services.Database
  alias ControlServer.Services.InternalDatabase
  alias ControlServer.Release

  describe "Database" do
    test "InternalDatabase is a default enabled service." do
      assert Database.active?() == false
      assert InternalDatabase.active?() == false
      Release.seed()

      assert Database.active?() == false
      assert InternalDatabase.active?() == true
    end
  end
end

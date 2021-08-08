defmodule ControlServer.Services.DatabaseTest do
  use ControlServer.DataCase

  alias ControlServer.Services.Database

  describe "Database" do
    test "Activate" do
      assert Database.active?() == false

      Database.activate!()

      assert Database.active?()
    end
  end
end

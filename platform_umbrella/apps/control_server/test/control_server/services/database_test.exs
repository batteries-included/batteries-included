defmodule ControlServer.Services.DatabaseTest do
  use ControlServer.DataCase

  alias ControlServer.Services.RunnableService
  alias ControlServer.Release

  import ExUnit.CaptureIO

  describe "Database" do
    test "InternalDatabase is a default enabled service." do
      assert RunnableService.active?(:database) == false
      assert RunnableService.active?(:database_internal) == false
      assert RunnableService.active?(:database_public) == false

      capture_io(fn ->
        Release.seed()
      end)

      assert RunnableService.active?(:database_public) == false
      assert RunnableService.active?(:database_internal)
      assert RunnableService.active?(:database)
    end
  end
end

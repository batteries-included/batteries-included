defmodule CommonCoreTest do
  use ExUnit.Case
  doctest CommonCore

  test "greets the world" do
    assert CommonCore.hello() == :world
  end
end

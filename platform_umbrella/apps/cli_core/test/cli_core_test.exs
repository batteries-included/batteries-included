defmodule CliCoreTest do
  use ExUnit.Case
  doctest CliCore

  test "greets the world" do
    assert CliCore.hello() == :world
  end
end

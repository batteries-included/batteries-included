defmodule BootstrapTest do
  use ExUnit.Case
  doctest Bootstrap

  test "greets the world" do
    assert Bootstrap.hello() == :world
  end
end

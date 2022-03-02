defmodule KubeStateTest do
  use ExUnit.Case
  doctest KubeState

  test "greets the world" do
    assert KubeState.hello() == :world
  end
end

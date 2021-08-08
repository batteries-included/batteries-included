defmodule KubeResourcesTest do
  use ExUnit.Case
  doctest KubeResources

  test "greets the world" do
    assert KubeResources.hello() == :world
  end
end

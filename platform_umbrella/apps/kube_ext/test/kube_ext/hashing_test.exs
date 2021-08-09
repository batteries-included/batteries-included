defmodule KubeExt.HashingTest do
  use ExUnit.Case

  alias KubeExt.Hashing

  test "Hashing.different?" do
    assert false == Hashing.different?([], [])
    assert false == Hashing.different?(%{test: 100}, %{test: 100})
  end
end

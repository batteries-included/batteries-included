defmodule VerifyTest do
  use Verify.TestCase, async: false

  @tag :cluster_test
  test "greets the world" do
    assert true
  end
end

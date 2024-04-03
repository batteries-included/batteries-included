defmodule CommonUI.IDHelpersTest do
  use ExUnit.Case

  alias CommonUI.IDHelpers

  test "provide_id/1 with nil id in assigns" do
    assigns = %{id: nil}
    assert %{:id => id} = IDHelpers.provide_id(assigns)
    assert String.length(id) == 16
  end

  test "provide_id/1 with id in assigns" do
    assigns = %{id: "123"}
    assert %{:id => id} = IDHelpers.provide_id(assigns)
    assert id == "123"
  end

  test "provide_id/1 with id in assigns rest" do
    assigns = %{rest: %{id: "123"}}
    assert %{:id => id} = IDHelpers.provide_id(assigns)
    assert id == "123"
  end

  test "provide_id/1 with no id in assigns" do
    assigns = %{}
    assert %{:id => id} = IDHelpers.provide_id(assigns)
    assert String.length(id) == 16
  end
end

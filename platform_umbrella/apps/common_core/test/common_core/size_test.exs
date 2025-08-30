defmodule CommonCore.SizeTest do
  use ExUnit.Case, async: true

  alias CommonCore.Size

  describe "type/0" do
    test "backing type is string" do
      assert :string == Size.type()
    end
  end

  describe "cast/1" do
    test "accepts atoms and strings for known sizes" do
      assert {:ok, :tiny} == Size.cast(:tiny)
      assert {:ok, :small} == Size.cast(:small)
      assert {:ok, :medium} == Size.cast(:medium)
      assert {:ok, :large} == Size.cast(:large)
      assert {:ok, :xlarge} == Size.cast(:xlarge)
      assert {:ok, :huge} == Size.cast(:huge)

      assert {:ok, :tiny} == Size.cast("tiny")
      assert {:ok, :small} == Size.cast("small")
    end

    test "rejects invalid" do
      assert :error == Size.cast("gigantic")
    end
  end

  describe "dump/load round trips" do
    test "round trips" do
      assert {:ok, "tiny"} == Size.dump(:tiny)
      assert {:ok, :tiny} == Size.load("tiny")
    end
  end

  test "options/0 returns tuples" do
    assert {"Tiny", :tiny} in Size.options()
    assert {"Huge", :huge} in Size.options()
  end
end

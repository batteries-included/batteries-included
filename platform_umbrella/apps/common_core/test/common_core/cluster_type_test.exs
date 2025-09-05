defmodule CommonCore.ClusterTypeTest do
  use ExUnit.Case, async: true

  alias CommonCore.ClusterType

  describe "type/0" do
    test "backing type is string" do
      assert :string == ClusterType.type()
    end
  end

  describe "cast/1" do
    test "accepts atoms" do
      assert {:ok, :kind} == ClusterType.cast(:kind)
      assert {:ok, :aws} == ClusterType.cast(:aws)
      assert {:ok, :azure} == ClusterType.cast(:azure)
      assert {:ok, :provided} == ClusterType.cast(:provided)
    end

    test "accepts strings" do
      assert {:ok, :kind} == ClusterType.cast("kind")
      assert {:ok, :aws} == ClusterType.cast("aws")
      assert {:ok, :azure} == ClusterType.cast("azure")
      assert {:ok, :provided} == ClusterType.cast("provided")
    end

    test "rejects invalid" do
      assert :error == ClusterType.cast("gcp")
    end
  end

  describe "dump/1 and load/1" do
    test "round trips" do
      assert {:ok, "kind"} == ClusterType.dump(:kind)
      assert {:ok, :kind} == ClusterType.load("kind")
    end
  end

  test "options/0 returns tuples" do
    assert {"Kind", :kind} in ClusterType.options()
    assert {"AWS", :aws} in ClusterType.options()
    assert {"Azure", :azure} in ClusterType.options()
    assert {"Provided", :provided} in ClusterType.options()
  end

  test "label/1 returns human friendly names" do
    assert ClusterType.label(:kind) == "Kind"
    assert ClusterType.label(:aws) == "AWS"
    assert ClusterType.label(:provided) == "Provided"
  end
end

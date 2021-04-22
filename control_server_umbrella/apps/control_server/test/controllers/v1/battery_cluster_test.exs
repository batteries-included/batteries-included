defmodule ControlServer.Controller.V1.BatteryClusterTest do
  @moduledoc false
  use ExUnit.Case, async: false
  alias ControlServer.Controller.V1.BatteryCluster

  describe "add/1" do
    test "returns :ok" do
      event = %{}
      result = BatteryCluster.add(event)
      assert result == :ok
    end
  end

  describe "modify/1" do
    test "returns :ok" do
      event = %{}
      result = BatteryCluster.modify(event)
      assert result == :ok
    end
  end

  describe "delete/1" do
    test "returns :ok" do
      event = %{}
      result = BatteryCluster.delete(event)
      assert result == :ok
    end
  end

  describe "reconcile/1" do
    test "returns :ok" do
      event = %{}
      result = BatteryCluster.reconcile(event)
      assert result == :ok
    end
  end
end

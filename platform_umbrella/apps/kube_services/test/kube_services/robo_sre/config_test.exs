defmodule KubeServices.RoboSRE.ConfigTest do
  use ExUnit.Case

  alias KubeServices.RoboSRE.Analyzers.StaleResourceAnalyzer
  alias KubeServices.RoboSRE.Config
  alias KubeServices.RoboSRE.Handlers.StaleResourceHandler

  describe "analyzer_mappings/0" do
    test "returns correct analyzer mappings" do
      mappings = Config.analyzer_mappings()

      assert is_map(mappings)
      assert mappings[:stale_resource] == StaleResourceAnalyzer
    end
  end

  describe "handler_mappings/0" do
    test "returns correct handler mappings" do
      mappings = Config.handler_mappings()

      assert is_map(mappings)
      assert mappings[:stale_resource] == [StaleResourceHandler]
    end
  end

  describe "get_analyzer/1" do
    test "returns analyzer for known issue type" do
      assert {:ok, StaleResourceAnalyzer} = Config.get_analyzer(:stale_resource)
    end

    test "returns error for unknown issue type" do
      assert {:error, :not_found} = Config.get_analyzer(:unknown_type)
    end
  end

  describe "get_handlers/1" do
    test "returns handlers for known issue type" do
      assert {:ok, [StaleResourceHandler]} = Config.get_handlers(:stale_resource)
    end

    test "returns error for unknown issue type" do
      assert {:error, :not_found} = Config.get_handlers(:unknown_type)
    end
  end
end

defmodule KubeServices.ConfigGeneratorTest do
  use ControlServer.DataCase

  alias KubeResources.ConfigGenerator

  def assert_named(%{} = resource) when is_map(resource) do
    real_name = K8s.Resource.name(resource)
    assert nil != real_name, "The resource should always be named"
  end

  def assert_named(resources) when is_list(resources) do
    Enum.each(resources, fn res -> assert_named(res) end)
  end

  def assert_named(nil = _resource), do: nil

  def assert_valid_json(resources) do
    assert match?({:ok, _value}, Jason.encode(resources))
  end

  def assert_contains_resources(resource_map, battery) do
    assert map_size(resource_map) >= 1,
           "Expect battery of type #{inspect(battery)} to have some k8 resources."
  end

  def assert_valid(resources) do
    assert_named(resources)
    assert_valid_json(resources)
  end

  describe "ConfigGenerator with everything enabled" do
    test "all battery resources are valid" do
      KubeExt.SystemState.SeedState.seed(:everythings)
      |> ConfigGenerator.materialize()
      |> then(&Map.values/1)
      |> Enum.each(&assert_valid/1)
    end
  end

  describe "ConfigGenerator a small set of batteries" do
    test "all battery resources are valid" do
      KubeExt.SystemState.SeedState.seed(:dev)
      |> ConfigGenerator.materialize()
      |> then(&Map.values/1)
      |> Enum.each(&assert_valid/1)
    end
  end
end

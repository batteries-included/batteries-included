defmodule KubeServices.ConfigGeneratorTest do
  use ExUnit.Case

  import K8s.Resource.FieldAccessors

  alias KubeResources.ConfigGenerator
  alias CommonCore.ApiVersionKind

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

  def assert_one_resouce_definition(resource_map) do
    resource_map
    |> Enum.map(fn {path, res} ->
      {{ApiVersionKind.resource_type!(res), namespace(res), name(res)}, path}
    end)
    |> Enum.group_by(fn {ident, _path} -> ident end, fn {_ident, path} -> path end)
    |> Enum.each(fn {ident, paths} ->
      assert length(paths) == 1,
             "There should only be one path defining, #{inspect(ident)}, found #{Enum.join(paths, ", ")}"
    end)

    resource_map
  end

  def assert_valid(resource) do
    assert_named(resource)
    assert_valid_json(resource)
  end

  describe "ConfigGenerator with everything enabled" do
    test "all battery resources are valid" do
      CommonCore.StateSummary.SeedState.seed(:everything)
      |> ConfigGenerator.materialize()
      |> then(&assert_one_resouce_definition/1)
      |> then(&Map.values/1)
      |> Enum.each(&assert_valid/1)
    end
  end

  describe "ConfigGenerator a small set of batteries" do
    test "all battery resources are valid" do
      CommonCore.StateSummary.SeedState.seed(:dev)
      |> ConfigGenerator.materialize()
      |> then(&Map.values/1)
      |> Enum.each(&assert_valid/1)
    end
  end
end

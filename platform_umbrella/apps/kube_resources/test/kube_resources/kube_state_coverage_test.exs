defmodule KubeServices.KubeStateCoverageTest do
  use ExUnit.Case

  import K8s.Resource.FieldAccessors

  alias KubeResources.ConfigGenerator
  alias KubeExt.ApiVersionKind

  describe "KubeState can watch for every battery" do
    test "All watchable" do
      KubeExt.SnapshotApply.SeedStateSnapshot.seed(:everything)
      |> ConfigGenerator.materialize()
      |> Enum.map(fn {_path, resource} -> {api_version(resource), kind(resource)} end)
      |> Enum.each(fn {api_version, kind} ->
        assert ApiVersionKind.is_watchable(api_version, kind),
               "Expected #{api_version} and #{kind} to be know types that can be watched by KubeState"
      end)
    end
  end
end

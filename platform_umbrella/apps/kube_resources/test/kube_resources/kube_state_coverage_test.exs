defmodule KubeServices.KubeStateCoverageTest do
  use ControlServer.DataCase

  alias KubeResources.ConfigGenerator
  alias ControlServer.Batteries.Installer
  alias ControlServer.Batteries.Catalog
  alias ControlServer.Batteries
  alias KubeExt.ApiVersionKind

  def assert_all_resources_watchable do
    Batteries.list_system_batteries()
    |> Enum.map(&ConfigGenerator.materialize/1)
    |> Enum.map(&KubeResources.unique_kinds/1)
    |> List.flatten()
    |> Enum.each(fn {api_version, kind} ->
      assert ApiVersionKind.is_watchable(api_version, kind),
             "Expected #{api_version} and #{kind} to be know types that can be watched by KubeState"
    end)
  end

  describe "KubeState can watch for every service" do
    test "All watchable" do
      Enum.each(
        Catalog.all(),
        fn catalog_battery ->
          Installer.install!(catalog_battery.type)
        end
      )

      assert_all_resources_watchable()
    end
  end
end

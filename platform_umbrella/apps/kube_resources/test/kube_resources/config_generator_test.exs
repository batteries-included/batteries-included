defmodule KubeServices.ConfigGeneratorTest do
  use ControlServer.DataCase

  alias KubeResources.ConfigGenerator
  alias ControlServer.Batteries.Catalog
  alias ControlServer.Batteries.Installer
  alias ControlServer.Batteries

  require Logger

  import KubeResources.ControlServerFactory

  describe "ConfigGenerator" do
    def assert_named(%{} = resource) when is_map(resource) do
      if nil == K8s.Resource.name(resource) do
        IO.inspect(resource)
      end

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
             "Expect battery of type #{inspect(battery.type)} to have some k8 resources."
    end

    def assert_valid(resources) do
      assert_named(resources)
      assert_valid_json(resources)
    end

    setup do
      {:ok,
       battery_map:
         Catalog.all()
         |> Enum.map(fn battery -> {battery.type, Installer.install!(battery.type)} end)
         |> Enum.into(%{}),
       postgres: insert(:postgres),
       redis: insert(:redis),
       notebook: insert(:notebook),
       ceph_cluster: insert(:ceph_cluster),
       ceph_filesystem: insert(:ceph_filesystem)}
    end

    test "all battery resources are valid" do
      Batteries.list_system_batteries()
      |> Enum.map(fn battery -> {battery, ConfigGenerator.materialize(battery)} end)
      |> Enum.map(fn {battery, rm} ->
        assert_contains_resources(rm, battery)
        rm
      end)
      |> Enum.reduce(%{}, &Map.merge/2)
      |> then(&Map.values/1)
      |> Enum.each(&assert_valid/1)
    end
  end
end

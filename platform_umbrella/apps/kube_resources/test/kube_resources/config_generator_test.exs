defmodule KubeServices.ConfigGeneratorTest do
  use ControlServer.DataCase

  alias KubeResources.ConfigGenerator
  alias ControlServer.Services.RunnableService
  alias ControlServer.Services

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

    def assert_contains_resources(resource_map, service) do
      assert map_size(resource_map) >= 1,
             "Expect service of type #{inspect(service.service_type)} to have some k8 resources."
    end

    def assert_valid(resources) do
      assert_named(resources)
      assert_valid_json(resources)
    end

    setup do
      service_map =
        RunnableService.services()
        |> Enum.map(fn s -> {s.service_type, RunnableService.activate!(s)} end)
        |> Enum.into(%{})

      postgres = insert(:postgres)
      redis = insert(:redis)
      notebook = insert(:notebook)
      ceph_cluster = insert(:ceph_cluster)
      ceph_filesystem = insert(:ceph_filesystem)

      {:ok,
       services_activate_map: service_map,
       postgres: postgres,
       redis: redis,
       notebook: notebook,
       ceph_cluster: ceph_cluster,
       ceph_filesystem: ceph_filesystem}
    end

    test "all service resources are valid" do
      Services.all_including_config()
      |> Enum.map(fn service -> {service, ConfigGenerator.materialize(service)} end)
      |> Enum.map(fn {service, rm} ->
        assert_contains_resources(rm, service)
        rm
      end)
      |> Enum.reduce(%{}, &Map.merge/2)
      |> then(&Map.values/1)
      |> Enum.each(&assert_valid/1)
    end
  end
end

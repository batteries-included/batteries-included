defmodule KubeServices.ConfigGeneratorTest do
  use ControlServer.DataCase

  alias KubeResources.ConfigGenerator
  alias ControlServer.Services.RunnableService
  alias ControlServer.Services

  require Logger

  describe "ConfigGenerator" do
    def assert_named(%{} = resource) when is_map(resource) do
      if nil == K8s.Resource.name(resource) do
        IO.inspect(resource)
      end

      assert nil != K8s.Resource.name(resource)
    end

    def assert_named(resources) when is_list(resources) do
      Enum.each(resources, fn res -> assert_named(res) end)
    end

    def assert_named(nil = _resource), do: nil

    setup do
      {:ok,
       services_activate_map:
         RunnableService.services()
         |> Enum.map(fn s -> {s.service_type, RunnableService.activate!(s)} end)
         |> Enum.into(%{})}
    end

    test "materialize all the configs" do
      Services.list_base_services()
      |> Enum.each(fn service ->
        configs = ConfigGenerator.materialize(service)

        assert map_size(configs) >= 1
      end)
    end

    test "all are named" do
      Services.list_base_services()
      |> Enum.map(&ConfigGenerator.materialize/1)
      |> Enum.flat_map(&Map.values/1)
      |> Enum.each(&assert_named/1)
    end

    test "Activate database_internal" do
      RunnableService.activate!(:database_internal)
      RunnableService.activate!(:database_internal)
    end

    test "everything can turn into json" do
      Services.list_base_services()
      |> Enum.each(fn base_service ->
        configs = ConfigGenerator.materialize(base_service)

        assert match?({:ok, _value}, Jason.encode(configs))
      end)
    end
  end
end

defmodule ControlServer.TraditionalServicesTest do
  use ControlServer.DataCase

  alias ControlServer.TraditionalServices

  describe "traditional_services" do
    import ControlServer.TraditionalServicesFixtures

    alias CommonCore.TraditionalServices.Service

    @invalid_attrs %{name: nil, containers: nil, init_containers: nil, env_values: nil}

    test "list_traditional_services/0 returns all traditional services" do
      service = service_fixture()
      assert 1 == length(TraditionalServices.list_traditional_services())
      [found] = TraditionalServices.list_traditional_services()

      assert found.name == service.name
      assert found.containers == service.containers
      assert found.init_containers == service.init_containers
      assert found.env_values == service.env_values
    end

    test "list_traditional_services/1 returns paginated traditional services" do
      pagination_test(&service_fixture/1, &TraditionalServices.list_traditional_services/1)
    end

    test "get_service!/1 returns the service with given id" do
      service = service_fixture()
      found = TraditionalServices.get_service!(service.id)
      assert found
      assert found.name == service.name
      assert found.containers == service.containers
      assert found.init_containers == service.init_containers
      assert found.env_values == service.env_values
      assert found.num_instances == service.num_instances
    end

    test "create_service/1 with valid data creates a service" do
      valid_attrs = %{name: "some-name", containers: [], init_containers: [], env_values: []}

      assert {:ok, %Service{} = service} = TraditionalServices.create_service(valid_attrs)
      assert service.name == "some-name"
      assert service.containers == []
      assert service.init_containers == []
      assert service.env_values == []
    end

    test "create_service/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = TraditionalServices.create_service(@invalid_attrs)
    end

    test "find_or_create_service/1 with valid data creates a service if not exists" do
      valid_attrs = %{name: "some-name", containers: [], init_containers: [], env_values: []}

      assert {:ok, %{created: service}} = TraditionalServices.find_or_create_service(valid_attrs)
      assert service.name == "some-name"
      assert service.containers == []
      assert service.init_containers == []
      assert service.env_values == []
    end

    test "find_or_create_service/1 with valid data returns existing service if exists" do
      valid_attrs = %{name: "some-name", containers: [], init_containers: [], env_values: []}

      assert {:ok, %{created: created}} = TraditionalServices.find_or_create_service(valid_attrs)
      assert {:ok, %{selected: selected}} = TraditionalServices.find_or_create_service(valid_attrs)
      assert created.name == selected.name
      assert created.containers == selected.containers
      assert created.init_containers == selected.init_containers
      assert created.env_values == selected.env_values
      assert 1 = length(TraditionalServices.list_traditional_services())
    end

    test "update_service/2 with valid data updates the service" do
      service = service_fixture()
      update_attrs = %{name: "some-updated-name", containers: [], init_containers: [], env_values: []}

      assert {:ok, %Service{} = service} = TraditionalServices.update_service(service, update_attrs)
      assert service.name == "some-updated-name"
      assert service.containers == []
      assert service.init_containers == []
      assert service.env_values == []
    end

    test "update_service/2 with invalid data returns error changeset" do
      service = service_fixture()
      assert {:error, %Ecto.Changeset{}} = TraditionalServices.update_service(service, @invalid_attrs)
      expected = Map.delete(service, :virtual_size)
      assert expected == service.id |> TraditionalServices.get_service!() |> Map.delete(:virtual_size)
    end

    test "delete_service/1 deletes the service" do
      service = service_fixture()
      assert {:ok, %Service{}} = TraditionalServices.delete_service(service)
      assert_raise Ecto.NoResultsError, fn -> TraditionalServices.get_service!(service.id) end
    end

    test "change_service/1 returns a service changeset" do
      service = service_fixture()
      assert %Ecto.Changeset{} = TraditionalServices.change_service(service)
    end
  end
end

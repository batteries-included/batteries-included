defmodule ControlServer.BackendTest do
  use ControlServer.DataCase

  alias ControlServer.Backend

  describe "backend_services" do
    import ControlServer.BackendFixtures

    alias CommonCore.Backend.Service

    @invalid_attrs %{name: nil, containers: nil, init_containers: nil, env_values: nil}

    test "list_backend_services/0 returns all backend_services" do
      service = service_fixture()
      assert 1 == length(Backend.list_backend_services())
      [found] = Backend.list_backend_services()

      assert found.name == service.name
      assert found.containers == service.containers
      assert found.init_containers == service.init_containers
      assert found.env_values == service.env_values
    end

    test "get_service!/1 returns the service with given id" do
      service = service_fixture()
      found = Backend.get_service!(service.id)
      assert found != nil
      assert found.name == service.name
      assert found.containers == service.containers
      assert found.init_containers == service.init_containers
      assert found.env_values == service.env_values
      assert found.num_instances == service.num_instances
    end

    test "create_service/1 with valid data creates a service" do
      valid_attrs = %{name: "some-name", containers: [], init_containers: [], env_values: []}

      assert {:ok, %Service{} = service} = Backend.create_service(valid_attrs)
      assert service.name == "some-name"
      assert service.containers == []
      assert service.init_containers == []
      assert service.env_values == []
    end

    test "create_service/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Backend.create_service(@invalid_attrs)
    end

    test "update_service/2 with valid data updates the service" do
      service = service_fixture()
      update_attrs = %{name: "some-updated-name", containers: [], init_containers: [], env_values: []}

      assert {:ok, %Service{} = service} = Backend.update_service(service, update_attrs)
      assert service.name == "some-updated-name"
      assert service.containers == []
      assert service.init_containers == []
      assert service.env_values == []
    end

    test "update_service/2 with invalid data returns error changeset" do
      service = service_fixture()
      assert {:error, %Ecto.Changeset{}} = Backend.update_service(service, @invalid_attrs)
      expected = Map.delete(service, :virtual_size)
      assert expected == service.id |> Backend.get_service!() |> Map.delete(:virtual_size)
    end

    test "delete_service/1 deletes the service" do
      service = service_fixture()
      assert {:ok, %Service{}} = Backend.delete_service(service)
      assert_raise Ecto.NoResultsError, fn -> Backend.get_service!(service.id) end
    end

    test "change_service/1 returns a service changeset" do
      service = service_fixture()
      assert %Ecto.Changeset{} = Backend.change_service(service)
    end
  end
end

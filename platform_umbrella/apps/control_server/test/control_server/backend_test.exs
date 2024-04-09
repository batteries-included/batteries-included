defmodule ControlServer.BackendTest do
  use ControlServer.DataCase

  alias ControlServer.Backend

  describe "backend_services" do
    import ControlServer.BackendFixtures

    alias CommonCore.Backend.Service

    @invalid_attrs %{name: nil, containers: nil, init_containers: nil, env_values: nil}

    test "list_backend_services/0 returns all backend_services" do
      service = service_fixture()
      assert Backend.list_backend_services() == [service]
    end

    test "get_service!/1 returns the service with given id" do
      service = service_fixture()
      assert Backend.get_service!(service.id) == service
    end

    test "create_service/1 with valid data creates a service" do
      valid_attrs = %{name: "some name", containers: [], init_containers: [], env_values: []}

      assert {:ok, %Service{} = service} = Backend.create_service(valid_attrs)
      assert service.name == "some name"
      assert service.containers == []
      assert service.init_containers == []
      assert service.env_values == []
    end

    test "create_service/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Backend.create_service(@invalid_attrs)
    end

    test "update_service/2 with valid data updates the service" do
      service = service_fixture()
      update_attrs = %{name: "some updated name", containers: [], init_containers: [], env_values: []}

      assert {:ok, %Service{} = service} = Backend.update_service(service, update_attrs)
      assert service.name == "some updated name"
      assert service.containers == []
      assert service.init_containers == []
      assert service.env_values == []
    end

    test "update_service/2 with invalid data returns error changeset" do
      service = service_fixture()
      assert {:error, %Ecto.Changeset{}} = Backend.update_service(service, @invalid_attrs)
      assert service == Backend.get_service!(service.id)
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

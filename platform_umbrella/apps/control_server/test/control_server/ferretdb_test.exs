defmodule ControlServer.FerretDBTest do
  use ControlServer.DataCase

  alias ControlServer.FerretDB

  describe "ferret_services" do
    import ControlServer.FerretDBFixtures

    alias CommonCore.FerretDB.FerretService

    @invalid_attrs %{instances: nil, cpu_requested: nil, cpu_limits: nil, memory_requested: nil, memory_limits: nil}

    test "list_ferret_services/0 returns all ferret services" do
      ferret_service = ferret_service_fixture()
      assert FerretDB.list_ferret_services() == [ferret_service]
    end

    test "list_ferret_services/1 returns paginated ferret services" do
      pagination_test(&ferret_service_fixture/1, &FerretDB.list_ferret_services/1)
    end

    test "get_ferret_service!/1 returns the ferret_service with given id" do
      ferret_service = ferret_service_fixture()
      assert FerretDB.get_ferret_service!(ferret_service.id) == ferret_service
    end

    test "create_ferret_service/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = FerretDB.create_ferret_service(@invalid_attrs)
    end

    test "update_ferret_service/2 with valid data updates the ferret_service" do
      ferret_service = ferret_service_fixture()
      update_attrs = %{instances: 43, cpu_requested: 43, cpu_limits: 43, memory_requested: 43, memory_limits: 43}

      assert {:ok, %FerretService{} = ferret_service} = FerretDB.update_ferret_service(ferret_service, update_attrs)
      assert ferret_service.instances == 43
      assert ferret_service.cpu_requested == 43
      assert ferret_service.cpu_limits == 43
      assert ferret_service.memory_requested == 43
      assert ferret_service.memory_limits == 43
    end

    test "update_ferret_service/2 with invalid data returns error changeset" do
      ferret_service = ferret_service_fixture()
      assert {:error, %Ecto.Changeset{}} = FerretDB.update_ferret_service(ferret_service, @invalid_attrs)
      assert ferret_service == FerretDB.get_ferret_service!(ferret_service.id)
    end

    test "delete_ferret_service/1 deletes the ferret_service" do
      ferret_service = ferret_service_fixture()
      assert {:ok, %FerretService{}} = FerretDB.delete_ferret_service(ferret_service)
      assert_raise Ecto.NoResultsError, fn -> FerretDB.get_ferret_service!(ferret_service.id) end
    end

    test "change_ferret_service/1 returns a ferret_service changeset" do
      ferret_service = ferret_service_fixture()
      assert %Ecto.Changeset{} = FerretDB.change_ferret_service(ferret_service)
    end
  end
end

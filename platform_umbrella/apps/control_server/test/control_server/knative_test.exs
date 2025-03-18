defmodule ControlServer.KnativeTest do
  use ControlServer.DataCase

  alias CommonCore.Knative.Service
  alias ControlServer.Knative

  describe "services" do
    import ControlServer.KnativeFixtures

    # TODO: Add string validity tests for names and images, not just presence:
    #       * empty string
    #       * invalid characters
    #       * wrong type
    @invalid_name %{name: nil, containers: [%{image: "test-image"}]}
    @invalid_image %{name: "invalid-image-test", containers: [%{image: "test-image"}]}

    test "list_services/0 returns all services" do
      service = service_fixture()
      assert Knative.list_services() == [service]
    end

    test "list_services/1 returns paginated services" do
      pagination_test(&service_fixture/1, &Knative.list_services/1)
    end

    test "get_service!/1 returns the service with given id" do
      service = service_fixture()
      assert Knative.get_service!(service.id) == service
    end

    test "create_service/1 with valid data creates a service" do
      valid_attrs = %{name: "some-name", image: "some-image"}

      assert {:ok, %Service{} = service} = Knative.create_service(valid_attrs)
      assert service.name == valid_attrs.name
    end

    test "create_service/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Knative.create_service(@invalid_name)
      assert {:error, %Ecto.Changeset{}} = Knative.create_service(@invalid_image)
    end

    test "update_service/2 with valid data updates the service" do
      service = service_fixture()
      update_attrs = %{name: "some-updated-name"}

      assert {:ok, %Service{} = service} = Knative.update_service(service, update_attrs)
      assert service.name == "some-updated-name"
    end

    test "update_service/2 with invalid data returns error changeset" do
      service = service_fixture()
      assert {:error, %Ecto.Changeset{}} = Knative.update_service(service, @invalid_name)
      assert {:error, %Ecto.Changeset{}} = Knative.update_service(service, @invalid_image)
      assert service == Knative.get_service!(service.id)
    end

    test "delete_service/1 deletes the service" do
      service = service_fixture()
      assert {:ok, %Service{}} = Knative.delete_service(service)
      assert_raise Ecto.NoResultsError, fn -> Knative.get_service!(service.id) end
    end

    test "change_service/1 returns a service changeset" do
      service = service_fixture()
      assert %Ecto.Changeset{} = Knative.change_service(service)
    end
  end
end

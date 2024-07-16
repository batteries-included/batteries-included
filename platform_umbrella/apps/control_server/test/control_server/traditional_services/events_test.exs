defmodule ControlServer.TraditionalServices.EventsTest do
  use ControlServer.DataCase

  import ControlServer.Factory

  describe "ControlServer.TraditionalServices and EventCenter.Database" do
    test "create backend_service broadcasts an insert event" do
      :ok = EventCenter.Database.subscribe(:backend_service)

      assert {:ok, service} =
               ControlServer.TraditionalServices.create_service(params_for(:backend_service))

      service_id = service.id
      name = service.name
      containers = service.containers
      init_containers = service.init_containers
      env_values = service.env_values

      assert_received {:insert,
                       %{
                         name: ^name,
                         id: ^service_id,
                         containers: ^containers,
                         init_containers: ^init_containers,
                         env_values: ^env_values
                       }}
    end

    test "update backend_service broadcasts an update event" do
      :ok = EventCenter.Database.subscribe(:backend_service)

      service = insert(:backend_service)

      assert {:ok, service} =
               ControlServer.TraditionalServices.update_service(service, %{name: "new-name"})

      service_id = service.id
      containers = service.containers
      init_containers = service.init_containers
      env_values = service.env_values

      assert_received {:update,
                       %{
                         name: "new-name",
                         id: ^service_id,
                         containers: ^containers,
                         init_containers: ^init_containers,
                         env_values: ^env_values
                       }}
    end
  end
end

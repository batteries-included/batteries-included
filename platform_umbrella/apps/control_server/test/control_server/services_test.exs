defmodule ControlServer.ServicesTest do
  use ControlServer.DataCase

  alias ControlServer.Services

  describe "base_services" do
    alias ControlServer.Services.BaseService

    @valid_attrs %{
      root_path: "some root_path",
      config: %{},
      service_type: :prometheus
    }
    @update_attrs %{
      root_path: "some updated root_path",
      config: %{},
      service_type: :prometheus
    }
    @invalid_attrs %{root_path: nil, config: nil, service_type: nil}

    def base_service_fixture(attrs \\ %{}) do
      {:ok, base_service} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Services.create_base_service()

      base_service
    end

    test "list_base_services/0 returns all base_services" do
      base_service = base_service_fixture()
      assert Enum.member?(Services.all_including_config(), base_service)
    end

    test "get_base_service!/1 returns the base_service with given id" do
      base_service = base_service_fixture()
      assert Services.get_base_service!(base_service.id) == base_service
    end

    test "create_base_service/1 with valid data creates a base_service" do
      assert {:ok, %BaseService{} = base_service} = Services.create_base_service(@valid_attrs)
      assert base_service.root_path == "some root_path"
      assert base_service.config == %{}
    end

    test "create_base_service/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Services.create_base_service(@invalid_attrs)
    end

    test "update_base_service/2 with valid data updates the base_service" do
      base_service = base_service_fixture()

      assert {:ok, %BaseService{} = base_service} =
               Services.update_base_service(base_service, @update_attrs)

      assert base_service.root_path == "some updated root_path"
      assert base_service.config == %{}
    end

    test "update_base_service/2 with invalid data returns error changeset" do
      base_service = base_service_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Services.update_base_service(base_service, @invalid_attrs)

      assert base_service == Services.get_base_service!(base_service.id)
    end

    test "delete_base_service/1 deletes the base_service" do
      base_service = base_service_fixture()
      assert {:ok, %BaseService{}} = Services.delete_base_service(base_service)
      assert_raise Ecto.NoResultsError, fn -> Services.get_base_service!(base_service.id) end
    end
  end
end

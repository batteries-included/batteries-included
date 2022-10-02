defmodule ControlServer.BatteriesTest do
  use ControlServer.DataCase

  alias ControlServer.Batteries

  describe "system_batteries" do
    alias ControlServer.Batteries.SystemBattery

    import ControlServer.BatteriesFixtures

    @invalid_attrs %{config: nil, group: nil, type: nil}

    test "list_system_batteries/0 returns all system_batteries" do
      system_battery = system_battery_fixture()
      assert Batteries.list_system_batteries() == [system_battery]
    end

    test "get_system_battery!/1 returns the system_battery with given id" do
      system_battery = system_battery_fixture()
      assert Batteries.get_system_battery!(system_battery.id) == system_battery
    end

    test "create_system_battery/1 with valid data creates a system_battery" do
      valid_attrs = %{config: %{}, group: :net_sec, type: :istio_istiod}

      assert {:ok, %SystemBattery{} = system_battery} =
               Batteries.create_system_battery(valid_attrs)

      assert system_battery.config == %{}
      assert system_battery.group == :net_sec
      assert system_battery.type == :istio_istiod
    end

    test "create_system_battery/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Batteries.create_system_battery(@invalid_attrs)
    end

    test "update_system_battery/2 with valid data updates the system_battery" do
      system_battery = system_battery_fixture()

      update_attrs = %{
        config: %{test: 110},
        group: :ml,
        type: :notebooks
      }

      assert {:ok, %SystemBattery{} = system_battery} =
               Batteries.update_system_battery(system_battery, update_attrs)

      assert system_battery.config == %{test: 110}
      assert system_battery.group == :ml
      assert system_battery.type == :notebooks
    end

    test "update_system_battery/2 with invalid data returns error changeset" do
      system_battery = system_battery_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Batteries.update_system_battery(system_battery, @invalid_attrs)

      assert system_battery == Batteries.get_system_battery!(system_battery.id)
    end

    test "delete_system_battery/1 deletes the system_battery" do
      system_battery = system_battery_fixture()
      assert {:ok, %SystemBattery{}} = Batteries.delete_system_battery(system_battery)
      assert_raise Ecto.NoResultsError, fn -> Batteries.get_system_battery!(system_battery.id) end
    end

    test "change_system_battery/1 returns a system_battery changeset" do
      system_battery = system_battery_fixture()
      assert %Ecto.Changeset{} = Batteries.change_system_battery(system_battery)
    end
  end
end

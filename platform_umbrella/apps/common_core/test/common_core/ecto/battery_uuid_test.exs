defmodule CommonCore.Ecto.BatteryUUIDTest do
  use ExUnit.Case

  alias CommonCore.Ecto.BatteryUUID

  @test_prefixed_uuid "batt_ca695f31d27c44159d9e079ccb37d9f7"
  @test_invaild_uuid "batt_ca695f31d27xxfT"

  @test_raw_uuid Ecto.UUID.dump!("ca695f31-d27c-4415-9d9e-079ccb37d9f7")

  test "cast/2" do
    assert BatteryUUID.cast(@test_prefixed_uuid) == {:ok, @test_prefixed_uuid}
    assert BatteryUUID.cast(nil) == {:ok, nil}
    assert BatteryUUID.cast("test_" <> @test_prefixed_uuid) == :error
    assert BatteryUUID.cast(@test_invaild_uuid) == :error
  end

  test "load/1" do
    assert BatteryUUID.load(@test_raw_uuid) == {:ok, @test_prefixed_uuid}
    assert BatteryUUID.load(nil) == :error
    assert BatteryUUID.load(@test_invaild_uuid) == :error
  end

  test "dump/1" do
    assert BatteryUUID.dump(@test_prefixed_uuid) == {:ok, @test_raw_uuid}
  end

  test "autogenerate/0" do
    assert String.starts_with?(BatteryUUID.autogenerate(), "batt_")
    assert String.length(BatteryUUID.autogenerate()) == 37
  end
end

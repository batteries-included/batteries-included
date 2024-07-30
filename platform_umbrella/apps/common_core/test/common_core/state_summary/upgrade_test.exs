defmodule CommonCore.StateSummary.UpgradeTest do
  use ExUnit.Case

  import CommonCore.Factory

  describe "Days of the week" do
    # On Call sucks. Don't deploy things on the days that you don't have
    # engineers there to fix it. Set that as our defaults.
    test "sunday isn't an upgrade day" do
      captured_at = DateTime.new!(Date.new!(2024, 7, 28), Time.new!(19, 42, 0, 0), "Etc/UTC")
      state_summary = build(:state_summary, captured_at: captured_at)
      assert !CommonCore.StateSummary.Core.upgrade_time?(state_summary)
    end

    test "monday is an upgrade day" do
      captured_at = DateTime.new!(Date.new!(2024, 7, 29), Time.new!(19, 20, 0, 0), "Etc/UTC")
      state_summary = build(:state_summary, captured_at: captured_at)
      assert CommonCore.StateSummary.Core.upgrade_time?(state_summary)
    end
  end

  test "gives the stable image on upgrade day" do
    captured_at = DateTime.new!(Date.new!(2024, 7, 29), Time.new!(19, 20, 0, 0), "Etc/UTC")
    state_summary = build(:state_summary, captured_at: captured_at)

    assert CommonCore.StateSummary.Core.controlserver_image(state_summary) ==
             "public.ecr.aws/batteries-included/control-server:v100.0.0"
  end

  test "gives the default image with a nil captured_at" do
    state_summary = build(:state_summary, captured_at: nil)

    assert CommonCore.StateSummary.Core.controlserver_image(state_summary) ==
             CommonCore.Defaults.Images.control_server_image()
  end

  test "give the default image when not in the upgrade window" do
    # Correct day but not the correct time yet.
    captured_at = DateTime.new!(Date.new!(2024, 7, 29), Time.new!(17, 20, 0, 0), "Etc/UTC")
    state_summary = build(:state_summary, captured_at: captured_at)

    assert CommonCore.StateSummary.Core.controlserver_image(state_summary) ==
             CommonCore.Defaults.Images.control_server_image()
  end
end

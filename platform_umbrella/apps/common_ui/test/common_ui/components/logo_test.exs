defmodule CommonUI.Components.LogoTest do
  use Heyya.SnapshotTest

  import CommonUI.Components.Logo

  component_snapshot_test "logo" do
    assigns = %{}

    ~H"""
    <.logo />
    """
  end
end

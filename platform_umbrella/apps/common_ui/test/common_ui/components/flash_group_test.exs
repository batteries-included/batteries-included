defmodule CommonUI.Components.FlashGroupTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.FlashGroup

  component_snapshot_test "flash group component" do
    assigns = %{}

    ~H"""
    <.flash_group
      id="foo"
      flash={
        %{
          "info" => "info",
          "success" => "success",
          "warning" => "warning",
          "error" => "error",
          "foo" => "bar"
        }
      }
    />
    """
  end

  component_snapshot_test "global flash group component" do
    assigns = %{}

    ~H"""
    <.flash_group
      global
      id="foo"
      flash={
        %{
          "global_info" => "info",
          "global_success" => "success",
          "global_warning" => "warning",
          "global_error" => "error"
        }
      }
    />
    """
  end
end

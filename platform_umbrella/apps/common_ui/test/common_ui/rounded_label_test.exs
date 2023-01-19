defmodule CommonUI.RoundedLabelTest do
  use Heyya.SnapshotTest

  import CommonUI.RoundedLabel

  component_snapshot_test "Basic" do
    assigns = %{}

    ~H"""
    <.rounded_label>Basic pill</.rounded_label>
    """
  end

  component_snapshot_test "with class" do
    assigns = %{}

    ~H"""
    <.rounded_label class="bg-pink-500">styled pill</.rounded_label>
    """
  end
end

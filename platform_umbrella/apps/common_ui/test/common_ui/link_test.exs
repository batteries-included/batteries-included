defmodule CommonUI.LinkTest do
  use CommonTesting.ComponentSnapshotTest

  import CommonUI.Link

  component_snapshot_test "Link styled type" do
    assigns = %{}

    ~H"""
    <.link variant="styled" navigate="/">Test Link</.link>
    """
  end

  component_snapshot_test "Link external" do
    assigns = %{}

    ~H"""
    <.link variant="external" href="https://google.com">Test External Link</.link>
    """
  end

  component_snapshot_test "Link default" do
    assigns = %{}

    ~H"""
    <.link navigate="/">Test unstyled Link</.link>
    """
  end
end

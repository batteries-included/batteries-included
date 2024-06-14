defmodule CommonUI.Components.LinkTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Link

  component_snapshot_test "Link default" do
    assigns = %{}

    ~H"""
    <.a navigate="/">Test Link</.a>
    """
  end

  component_snapshot_test "Link underlined type" do
    assigns = %{}

    ~H"""
    <.a variant="underlined" navigate="/">Test Link</.a>
    """
  end

  component_snapshot_test "Link icon type" do
    assigns = %{}

    ~H"""
    <.a variant="icon" icon={:face_smile} navigate="/">Test Link</.a>
    """
  end

  component_snapshot_test "Link external" do
    assigns = %{}

    ~H"""
    <.a variant="external" href="https://google.com">Test External Link</.a>
    """
  end

  component_snapshot_test "Link bordered" do
    assigns = %{}

    ~H"""
    <.a variant="bordered" navigate="/">Test Link</.a>
    """
  end

  component_snapshot_test "Link bordered external" do
    assigns = %{}

    ~H"""
    <.a variant="bordered" href="https://google.com">Test External Link</.a>
    """
  end
end

defmodule CommonUI.Components.LinkTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Link

  component_snapshot_test "Link styled type" do
    assigns = %{}

    ~H"""
    <.a variant="styled" navigate="/">Test Link</.a>
    """
  end

  component_snapshot_test "Link external" do
    assigns = %{}

    ~H"""
    <.a variant="external" href="https://google.com">Test External Link</.a>
    """
  end

  component_snapshot_test "Link default" do
    assigns = %{}

    ~H"""
    <.a navigate="/">Test unstyled Link</.a>
    """
  end

  component_snapshot_test "Link patch" do
    assigns = %{}

    ~H"""
    <.a patch="/test">Test patch</.a>
    """
  end

  component_snapshot_test "Link patch with variant" do
    assigns = %{}

    ~H"""
    <.a patch="/test" variant="styled">Test patch with var</.a>
    """
  end

  component_snapshot_test "Link with just href" do
    assigns = %{}

    ~H"""
    <.a href="https://www.google.com/">Test bare href</.a>
    """
  end
end

defmodule CommonUI.LinkTest do
  use Heyya

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

  component_snapshot_test "Link patch" do
    assigns = %{}

    ~H"""
    <.link patch="/test">Test patch</.link>
    """
  end

  component_snapshot_test "Link patch with variant" do
    assigns = %{}

    ~H"""
    <.link patch="/test" variant="styled">Test patch with var</.link>
    """
  end

  component_snapshot_test "Link with just href" do
    assigns = %{}

    ~H"""
    <.link href="https://www.google.com/">Test bare href</.link>
    """
  end
end

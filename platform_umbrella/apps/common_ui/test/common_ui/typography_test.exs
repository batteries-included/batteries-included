defmodule CommonUI.TypographyTest do
  use Heyya.SnapshotTest

  use CommonUI

  component_snapshot_test "default h1" do
    assigns = %{}

    ~H"""
    <.h1>Test Header</.h1>
    """
  end

  component_snapshot_test "h1 with class" do
    assigns = %{needed_class: "m-10"}

    ~H"""
    <.h1 class={@needed_class}>Test Header With Class</.h1>
    """
  end

  component_snapshot_test "default h2" do
    assigns = %{}

    ~H"""
    <.h2>Test H2 Header</.h2>
    """
  end

  component_snapshot_test "default h3" do
    assigns = %{}

    ~H"""
    <.h3>Test H3 Header</.h3>
    """
  end
end

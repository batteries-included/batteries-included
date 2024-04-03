defmodule CommonUI.Components.TypographyTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Typography

  component_snapshot_test "default h1" do
    assigns = %{}

    ~H"""
    <.h1>Test Header</.h1>
    """
  end

  component_snapshot_test "h1 with sub header" do
    assigns = %{}

    ~H"""
    <.h1>
      Header<:sub_header>with sub</:sub_header>
    </.h1>
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

  component_snapshot_test "default h4" do
    assigns = %{}

    ~H"""
    <.h4>Test H4 Accent Color Header</.h4>
    """
  end
end

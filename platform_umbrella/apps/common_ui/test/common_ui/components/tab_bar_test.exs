defmodule CommonUI.Components.TabBarTest do
  use Heyya.SnapshotTest

  import CommonUI.Components.TabBar

  component_snapshot_test "default tab bar" do
    assigns = %{}

    ~H"""
    <.tab_bar>
      <:tab phx-click="test">Title</:tab>
      <:tab patch="/second_path">Another Title</:tab>
    </.tab_bar>
    """
  end

  component_snapshot_test "secondary tab bar" do
    assigns = %{}

    ~H"""
    <.tab_bar variant="secondary">
      <:tab>Foo</:tab>
      <:tab selected>Bar</:tab>
      <:tab>Baz</:tab>
    </.tab_bar>
    """
  end

  component_snapshot_test "borderless tab bar" do
    assigns = %{}

    ~H"""
    <.tab_bar variant="borderless">
      <:tab>Foo</:tab>
      <:tab selected>Bar</:tab>
      <:tab>Baz</:tab>
    </.tab_bar>
    """
  end
end

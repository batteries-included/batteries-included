defmodule CommonUI.Components.TabBarTest do
  use Heyya.SnapshotTest

  import CommonUI.Components.TabBar

  component_snapshot_test "TabBar test" do
    assigns = %{}

    ~H"""
    <.tab_bar>
      <:tab phx-click="test">Title</:tab>
      <:tab patch="/second_path">Another Title</:tab>
    </.tab_bar>
    """
  end
end

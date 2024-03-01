defmodule CommonUI.Components.TabBarTest do
  use Heyya.SnapshotTest

  import CommonUI.Components.TabBar

  component_snapshot_test "TabBar test" do
    assigns = %{}

    ~H"""
    <.tab_bar>
      <.tab_item phx-click="test">Title</.tab_item>
      <.tab_item patch="/second_path">Another Title</.tab_item>
      <.tab_item navigate="/last_path">Yet Another Title</.tab_item>
    </.tab_bar>
    """
  end
end

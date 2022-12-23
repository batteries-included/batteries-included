defmodule CommonUI.TabBarTest do
  use Heyya.SnapshotTest

  import CommonUI.TabBar

  component_snapshot_test "TabBar test" do
    tabs = [
      {"Title", "/path", false},
      {"Another Title", "/second_path", true},
      {"Yet Another Title", "/last_path", false}
    ]

    assigns = %{tabs: tabs}

    ~H"""
    <.tab_bar tabs={@tabs} />
    """
  end
end

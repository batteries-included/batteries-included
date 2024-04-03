defmodule CommonUI.Components.TooltipTest do
  use Heyya.SnapshotCase
  use CommonUI.ComponentCase

  import CommonUI.Components.Tooltip

  describe "hover_tooltip" do
    component_snapshot_test "empty tooltip render" do
      assigns = %{}

      ~H"""
      <.hover_tooltip>this should render totally deviod of any wrappers</.hover_tooltip>
      """
    end

    component_snapshot_test "tooltip render" do
      assigns = %{}

      ~H"""
      <.hover_tooltip>
        <:tooltip>Test</:tooltip>
        Hello
      </.hover_tooltip>
      """
    end

    component_snapshot_test "tooltip with class" do
      assigns = %{}

      ~H"""
      <.hover_tooltip class="underline">
        <:tooltip>Test</:tooltip>
        Underlined text
      </.hover_tooltip>
      """
    end
  end

  describe "truncate_tooltip" do
    component_snapshot_test "it renders with short strings" do
      assigns = %{}

      ~H"""
      <.truncate_tooltip value="a" />
      """
    end

    component_snapshot_test "it renders with long strings" do
      assigns = %{}

      ~H"""
      <.truncate_tooltip value={String.duplicate("a", 100)} />
      """
    end
  end

  describe "tooltip" do
    test "it renders" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <div id="tooltip"></div>
        <.tooltip target_id="tooltip">
          Hi there
        </.tooltip>
        """)

      assert html =~ "Hi there"
      assert html =~ "data-tippy-options"
    end
  end
end

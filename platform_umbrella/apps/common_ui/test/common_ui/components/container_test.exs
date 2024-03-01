defmodule CommonUI.Components.ContainerTest do
  use Heyya.SnapshotTest

  import CommonUI.Components.Container

  describe "grid" do
    component_snapshot_test "with defaults" do
      assigns = %{}

      ~H"""
      <.grid>
        <div>test</div>
        <div>test</div>
      </.grid>
      """
    end

    component_snapshot_test "with single column" do
      assigns = %{}

      ~H"""
      <.grid columns={1}>
        <div>test</div>
        <div>test</div>
      </.grid>
      """
    end

    component_snapshot_test "with single gap single col" do
      assigns = %{}

      ~H"""
      <.grid gaps={1} columns={1}>
        <div>test</div>
        <div>test</div>
      </.grid>
      """
    end

    component_snapshot_test "with per breakpoint sizes" do
      assigns = %{}

      ~H"""
      <.grid gaps={[sm: 2, lg: 4, xl: 8]} columns={%{sm: 2, lg: 3, xl: 4}}>
        <div>test</div>
        <div>test</div>
      </.grid>
      """
    end
  end

  describe "flex" do
    test "flex contains things" do
      assigns = %{}

      ~H"""
      <.flex>
        <div>test</div>
        <div>test</div>
      </.flex>
      """
    end

    test "flex has column that flex-cols" do
      assigns = %{}

      ~H"""
      <.flex column>
        <div>test</div>
        <div>test</div>
      </.flex>
      """
    end
  end
end

defmodule CommonUI.Components.TabBarTest do
  use Heyya.SnapshotCase

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

  component_snapshot_test "navigation tab bar" do
    assigns = %{}

    ~H"""
    <.tab_bar variant="navigation">
      <:tab icon={:face_smile}>Foo</:tab>
      <:tab icon={:face_smile} selected>Bar</:tab>
      <:tab icon={:face_smile}>Baz</:tab>
    </.tab_bar>
    """
  end

  component_snapshot_test "minimal tab bar" do
    assigns = %{}

    ~H"""
    <.tab_bar variant="minimal">
      <:tab>My Account</:tab>
      <:tab>Company</:tab>
      <:tab selected>Team Members</:tab>
      <:tab>Billing</:tab>
    </.tab_bar>
    """
  end

  component_snapshot_test "minimal tab bar with icons" do
    assigns = %{}

    ~H"""
    <.tab_bar variant="minimal">
      <:tab icon={:user}>My Account</:tab>
      <:tab icon={:building_office}>Company</:tab>
      <:tab icon={:users} selected>Team Members</:tab>
      <:tab icon={:credit_card}>Billing</:tab>
    </.tab_bar>
    """
  end
end

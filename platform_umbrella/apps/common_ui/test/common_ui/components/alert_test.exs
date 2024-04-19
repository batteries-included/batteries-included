defmodule CommonUI.Components.AlertTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Alert

  component_snapshot_test "info inline alert component" do
    assigns = %{}

    ~H"""
    <.alert id="foo" variant="info">Foobar</.alert>
    """
  end

  component_snapshot_test "success inline alert component" do
    assigns = %{}

    ~H"""
    <.alert id="foo" variant="success">Foobar</.alert>
    """
  end

  component_snapshot_test "warning inline alert component" do
    assigns = %{}

    ~H"""
    <.alert id="foo" variant="warning">Foobar</.alert>
    """
  end

  component_snapshot_test "error inline alert component" do
    assigns = %{}

    ~H"""
    <.alert id="foo" variant="error">Foobar</.alert>
    """
  end

  component_snapshot_test "disconnected inline alert component" do
    assigns = %{}

    ~H"""
    <.alert id="foo" type="fixed" variant="disconnected" />
    """
  end

  component_snapshot_test "info fixed alert component" do
    assigns = %{}

    ~H"""
    <.alert id="foo" type="fixed" variant="info">Foobar</.alert>
    """
  end

  component_snapshot_test "hidden fixed alert component" do
    assigns = %{}

    ~H"""
    <.alert id="foo" type="fixed" autoshow={false}>Foobar</.alert>
    """
  end
end

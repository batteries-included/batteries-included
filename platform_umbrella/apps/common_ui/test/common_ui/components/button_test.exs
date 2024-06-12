defmodule CommonUI.Components.ButtonTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Button

  component_snapshot_test "default button" do
    assigns = %{}

    ~H"""
    <.button>Button</.button>
    """
  end

  component_snapshot_test "primary button" do
    assigns = %{}

    ~H"""
    <.button variant="primary">Button</.button>
    """
  end

  component_snapshot_test "secondary button" do
    assigns = %{}

    ~H"""
    <.button variant="secondary">Button</.button>
    """
  end

  component_snapshot_test "dark button" do
    assigns = %{}

    ~H"""
    <.button variant="dark">Button</.button>
    """
  end

  component_snapshot_test "danger button" do
    assigns = %{}

    ~H"""
    <.button variant="danger">Button</.button>
    """
  end

  component_snapshot_test "icon button" do
    assigns = %{}

    ~H"""
    <.button variant="icon">Button</.button>
    """
  end

  component_snapshot_test "icon_bordered button" do
    assigns = %{}

    ~H"""
    <.button variant="icon_bordered">Button</.button>
    """
  end

  component_snapshot_test "minimal button" do
    assigns = %{}

    ~H"""
    <.button variant="minimal">Button</.button>
    """
  end

  component_snapshot_test "button with icon" do
    assigns = %{}

    ~H"""
    <.button variant="primary" icon={:face_smile}>Button</.button>
    """
  end

  component_snapshot_test "button with icon on right" do
    assigns = %{}

    ~H"""
    <.button variant="primary" icon={:face_smile} icon_position={:right}>Button</.button>
    """
  end

  component_snapshot_test "button as a link" do
    assigns = %{}

    ~H"""
    <.button variant="primary" link="/">Button</.button>
    """
  end
end

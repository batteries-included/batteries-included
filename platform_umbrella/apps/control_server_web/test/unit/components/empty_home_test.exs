defmodule ControlServerWeb.Components.EmptyHomeTest do
  use Heyya.SnapshotCase

  import ControlServerWeb.EmptyHome

  component_snapshot_test "empty home" do
    assigns = %{install_path: "/batteries/monitoring"}

    ~H"""
    <.empty_home install_path={@install_path} />
    """
  end

  component_snapshot_test "with icon" do
    assigns = %{install_path: "/batteries/monitoring"}

    ~H"""
    <.empty_home icon={:chart_bar_square} install_path={@install_path} />
    """
  end
end

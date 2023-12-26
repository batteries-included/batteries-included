defmodule ControlServerWeb.Components.EmptyHomeTest do
  use Heyya.SnapshotTest

  import ControlServerWeb.EmptyHome

  component_snapshot_test "empty home" do
    assigns = %{install_path: "/batteries/monitoring"}

    ~H"""
    <.empty_home install_path={@install_path} />
    """
  end
end

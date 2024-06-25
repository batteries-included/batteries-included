defmodule ControlServerWeb.Components.EmptyHomeTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Typography
  import ControlServerWeb.EmptyHome

  component_snapshot_test "empty home" do
    assigns = %{install_path: "/batteries/monitoring"}

    ~H"""
    <.empty_home install_path={@install_path} />
    """
  end

  component_snapshot_test "with header" do
    assigns = %{install_path: "/batteries/monitoring"}

    ~H"""
    <.empty_home install_path={@install_path}>
      <:header>
        <.h2>Custom Header</.h2>
      </:header>
    </.empty_home>
    """
  end
end

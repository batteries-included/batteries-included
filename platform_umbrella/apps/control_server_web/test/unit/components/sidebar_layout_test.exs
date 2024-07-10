defmodule ControlServerWeb.Components.SidebarLayoutTest do
  use Heyya.SnapshotCase

  import ControlServerWeb.SidebarLayout

  component_snapshot_test "default sidebar_layout" do
    assigns = %{}

    ~H"""
    <.sidebar_layout
      current_page={:home}
      main_menu_items={[
        %{
          type: :home,
          name: "Home",
          path: "/",
          icon: :home
        }
      ]}
      bottom_menu_items={[
        %{
          type: :settings,
          name: "Settings",
          path: "/",
          icon: :adjustments_horizontal
        }
      ]}
    >
      <:logo>
        Logo
      </:logo>
    </.sidebar_layout>
    """
  end
end

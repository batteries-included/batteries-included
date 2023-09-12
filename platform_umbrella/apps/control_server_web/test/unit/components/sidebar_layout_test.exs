defmodule ControlServerWeb.Components.SidebarLayoutTest do
  use Heyya.SnapshotTest

  import ControlServerWeb.SidebarLayout

  component_snapshot_test "default sidebar_layout" do
    assigns = %{}

    ~H"""
    <.sidebar_layout
      current_page={:home}
      main_menu_items={[
        %{
          name: :home,
          label: "Home",
          path: "/",
          icon: :home
        }
      ]}
      bottom_menu_items={[
        %{
          name: :settings,
          label: "Settings",
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

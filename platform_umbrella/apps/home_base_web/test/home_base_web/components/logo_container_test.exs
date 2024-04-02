defmodule HomeBaseWeb.Components.LogoContainerTest do
  use Heyya.SnapshotTest

  import HomeBaseWeb.LogoContainer

  component_snapshot_test "renders the logo container" do
    assigns = %{}

    ~H"""
    <.logo_container title="Log in to your account">
      Hello from inside the logo container
    </.logo_container>
    """
  end
end

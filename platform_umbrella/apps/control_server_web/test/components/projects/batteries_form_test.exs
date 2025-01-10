defmodule ControlServerWeb.Projects.BatteriesFormTest do
  use ControlServerWeb.ConnCase

  import Phoenix.LiveViewTest

  alias ControlServer.Batteries.Installer
  alias ControlServerWeb.Projects.BatteriesForm
  alias KubeServices.SystemState.Summarizer

  setup do
    Installer.install!(:battery_core)
    Summarizer.new()
    :ok
  end

  test "should render project batteries form" do
    assert render_component(BatteriesForm, id: "project-batteries-form", inner_block: [], data: %{}) =~
             "Turn On Additional Batteries"
  end
end

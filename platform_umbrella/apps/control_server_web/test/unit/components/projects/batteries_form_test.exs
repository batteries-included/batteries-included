defmodule ControlServerWeb.Projects.BatteriesFormTest do
  use ExUnit.Case

  import Phoenix.LiveViewTest

  alias ControlServerWeb.Projects.BatteriesForm

  test "should render project batteries form" do
    assert render_component(BatteriesForm, id: "project-batteries-form", inner_block: [], data: %{}) =~
             "Turn On Additional Batteries"
  end
end

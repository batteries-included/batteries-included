defmodule ControlServerWeb.BatteriesFormComponentTest do
  use ExUnit.Case

  import Phoenix.LiveViewTest

  alias CommonCore.Batteries.Catalog
  alias ControlServerWeb.BatteriesFormComponent

  @battery Catalog.get(:redis)

  test "should render batteries installation form" do
    assert render_component(BatteriesFormComponent,
             id: "batteries-form",
             inner_block: [],
             battery: @battery,
             action: :new
           ) =~
             "Redis"
  end

  test "should render edit battery form" do
    assert render_component(BatteriesFormComponent,
             id: "batteries-form",
             inner_block: [],
             battery: @battery,
             action: :edit
           ) =~
             "Redis"
  end
end

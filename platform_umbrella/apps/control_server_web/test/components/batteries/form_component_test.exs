defmodule ControlServerWeb.BatteriesFormComponentTest do
  use ExUnit.Case

  import Phoenix.LiveViewTest

  alias CommonCore.Batteries.Catalog
  alias ControlServerWeb.BatteriesFormComponent

  @catalog_battery Catalog.get(:battery_core)

  test "should render batteries installation form" do
    assert render_component(BatteriesFormComponent,
             id: "new-battery-form",
             action: :new,
             catalog_battery: @catalog_battery,
             inner_block: []
           ) =~ "Upgrade Schedule"
  end
end

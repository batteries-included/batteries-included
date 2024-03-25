defmodule ControlServerWeb.Projects.DatabaseFormTest do
  use ExUnit.Case

  import Phoenix.LiveViewTest

  alias ControlServerWeb.Projects.DatabaseForm

  test "should render project database form" do
    assert render_component(DatabaseForm, id: "project-database-form", inner_block: []) =~
             "Database Only"
  end
end

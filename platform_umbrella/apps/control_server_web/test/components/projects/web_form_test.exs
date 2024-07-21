defmodule ControlServerWeb.Projects.WebFormTest do
  use ExUnit.Case

  import Phoenix.LiveViewTest

  alias ControlServerWeb.Projects.WebForm

  test "should render project web form" do
    assert render_component(WebForm, id: "project-web-form", inner_block: []) =~
             "Web"
  end
end

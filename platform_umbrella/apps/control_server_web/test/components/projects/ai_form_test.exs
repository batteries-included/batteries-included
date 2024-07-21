defmodule ControlServerWeb.Projects.AIFormTest do
  use ExUnit.Case

  import Phoenix.LiveViewTest

  alias ControlServerWeb.Projects.AIForm

  test "should render project AI form" do
    assert render_component(AIForm, id: "project-ai-form", inner_block: []) =~
             "Artificial Intelligence"
  end
end

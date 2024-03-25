defmodule ControlServerWeb.Projects.ProjectFormTest do
  use ExUnit.Case

  import Phoenix.LiveViewTest

  alias ControlServerWeb.Projects.ProjectForm

  test "should render project form" do
    assert render_component(ProjectForm, id: "project-form", inner_block: []) =~
             "Tell More About Your Project"
  end
end

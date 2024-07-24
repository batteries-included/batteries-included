defmodule ControlServerWeb.Projects.ProjectFormTest do
  use ExUnit.Case

  import Phoenix.LiveViewTest

  alias ControlServerWeb.Projects.ProjectForm

  test "should render project form" do
    assert render_component(ProjectForm, id: "project-form", inner_block: []) =~
             "Tell More About Your Project"
  end

  describe "get_name_for_resource/1" do
    test "replaces space with dash" do
      assert ProjectForm.get_name_for_resource(%{data: %{ProjectForm => %{"name" => "foo bar"}}}) == "foo-bar"
    end

    test "returns nil if name is not found" do
      refute ProjectForm.get_name_for_resource(%{})
    end
  end
end

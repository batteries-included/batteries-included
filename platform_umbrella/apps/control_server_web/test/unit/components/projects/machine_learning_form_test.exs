defmodule ControlServerWeb.Projects.MachineLearningFormTest do
  use ExUnit.Case

  import Phoenix.LiveViewTest

  alias ControlServerWeb.Projects.MachineLearningForm

  test "should render project machine learning form" do
    assert render_component(MachineLearningForm, id: "project-machine-learning-form", inner_block: []) =~
             "Machine Learning"
  end
end

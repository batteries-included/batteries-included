defmodule CommonUI.Test do
  use ExUnit.Case

  import Phoenix.LiveViewTest

  doctest CommonUI

  test "labeled_definition works" do
    title = "My title to be found"
    content = "Test Content for the component"

    render_component(&CommonUI.LabeledDefiniton.labeled_definition/1,
      title: title,
      contents: content
    ) =~ "<dt"

    render_component(&CommonUI.LabeledDefiniton.labeled_definition/1,
      title: title,
      contents: content
    ) =~ "<dd"

    render_component(&CommonUI.LabeledDefiniton.labeled_definition/1,
      title: title,
      contents: content
    ) =~ title

    render_component(&CommonUI.LabeledDefiniton.labeled_definition/1,
      title: title,
      contents: content
    ) =~ content
  end
end

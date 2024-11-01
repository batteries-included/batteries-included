defmodule Storybook.Components.Form do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Form.simple_form/1
  def imports, do: [{CommonUI.Components.Input, input: 1}, {CommonUI.Components.Button, button: 1}]
  def container, do: {:div, class: "w-full p-4"}

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          title: "Foo Bar",
          flash: %{"info" => "This is a flash message"}
        },
        slots: [
          ~s"""
          <.input name="name" value="" placeholder="Name" />
          <.input name="email" value="" placeholder="Email" />
          <:actions>
            <.button variant="primary">Submit</.button>
          </:actions>
          """
        ]
      }
    ]
  end
end

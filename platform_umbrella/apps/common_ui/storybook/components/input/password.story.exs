defmodule Storybook.Components.Input.Password do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Input.input/1
  def container, do: {:div, class: "w-full"}

  def variations do
    [
      %Variation{
        id: :password,
        attributes: %{
          type: "password",
          name: "foobar",
          value: ""
        }
      },
      %Variation{
        id: :disabled,
        attributes: %{
          type: "password",
          name: "foobar",
          value: "somereallylongpasswordthatwedontwanttoshowforsecurity",
          disabled: true
        }
      }
    ]
  end
end

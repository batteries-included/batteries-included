defmodule ControlServerWeb.Storybook.Button do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Button.button/1

  def attributes, do: []
  def slots, do: []

  def variations,
    do: [
      %Variation{
        id: :default,
        description: "Default Button",
        attributes: %{variant: "default"},
        slots: ["Default Button"]
      },
      %Variation{id: :filled, description: "Filled", attributes: %{variant: "filled"}, slots: ["Filled Button"]},
      %Variation{id: :unstyled, description: "Unstyled", attributes: %{variant: "unstyled"}, slots: ["I got no style"]}
    ]
end

defmodule Storybook.Components.Dropdown do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Dropdown.dropdown/1
  def imports, do: [{CommonUI.Components.Button, button: 1}]

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          class: "min-w-full"
        },
        slots: [
          ~s|<:trigger>|,
          ~s|  <.button icon={:chevron_down} icon_position={:right} variant="secondary">Open Dropdown</.button>|,
          ~s|</:trigger>|,
          ~s|<:item icon={:academic_cap}>Baz</:item>|,
          ~s|<:item icon={:beaker} selected>Foo</:item>|,
          ~s|<:item icon={:bug_ant}>Bar</:item>|
        ]
      }
    ]
  end
end

defmodule Storybook.Components.Dropdown do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Dropdown.dropdown/1

  def imports,
    do: [
      {CommonUI.Components.Button, button: 1},
      {CommonUI.Components.Dropdown, dropdown_link: 1},
      {CommonUI.Components.Dropdown, dropdown_hr: 1}
    ]

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
          ~s|<.dropdown_link icon={:academic_cap}>Baz</.dropdown_link>|,
          ~s|<.dropdown_hr />|,
          ~s|<.dropdown_link icon={:beaker} selected>Foo</.dropdown_link>|,
          ~s|<.dropdown_link icon={:bug_ant}>Bar</.dropdown_link>|
        ]
      }
    ]
  end
end

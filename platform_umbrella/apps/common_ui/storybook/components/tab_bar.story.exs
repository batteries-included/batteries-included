defmodule Storybook.Components.TabBar do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.TabBar.tab_bar/1
  def container, do: {:div, class: "w-full"}

  def variations do
    [
      %Variation{
        id: :primary,
        slots: [
          """
          <:tab>Foo</:tab>
          <:tab selected>Bar</:tab>
          <:tab>Baz</:tab>
          """
        ]
      },
      %Variation{
        id: :secondary,
        slots: [
          """
          <:tab>Foo</:tab>
          <:tab selected>Bar</:tab>
          <:tab>Baz</:tab>
          """
        ],
        attributes: %{
          variant: "secondary"
        }
      },
      %Variation{
        id: :borderless,
        slots: [
          """
          <:tab>Foo</:tab>
          <:tab selected>Bar</:tab>
          <:tab>Baz</:tab>
          """
        ],
        attributes: %{
          variant: "borderless"
        },
        template: """
        <div class="p-4 bg-gray-lightest">
          <.psb-variation />
        </div>
        """
      }
    ]
  end
end

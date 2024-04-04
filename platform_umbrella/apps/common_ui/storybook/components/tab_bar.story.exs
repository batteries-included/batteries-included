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
        id: :with_icons,
        slots: [
          """
          <:tab icon={:academic_cap}>Baz</:tab>
          <:tab icon={:beaker} selected>Foo</:tab>
          <:tab icon={:bug_ant}>Bar</:tab>
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
      },
      %Variation{
        id: :navigation,
        slots: [
          """
          <:tab icon={:academic_cap}>Baz</:tab>
          <:tab icon={:beaker} selected>Foo</:tab>
          <:tab icon={:bug_ant}>Bar</:tab>
          """
        ],
        attributes: %{
          variant: "navigation"
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

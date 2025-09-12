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
      },
      %Variation{
        id: :minimal,
        slots: [
          """
          <:tab>My Account</:tab>
          <:tab>Company</:tab>
          <:tab selected>Team Members</:tab>
          <:tab>Billing</:tab>
          """
        ],
        attributes: %{
          variant: "minimal"
        }
      },
      %Variation{
        id: :minimal_with_icons,
        slots: [
          """
          <:tab icon={:user}>My Account</:tab>
          <:tab icon={:building_office}>Company</:tab>
          <:tab icon={:users} selected>Team Members</:tab>
          <:tab icon={:credit_card}>Billing</:tab>
          """
        ],
        attributes: %{
          variant: "minimal"
        }
      }
    ]
  end
end

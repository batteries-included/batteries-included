defmodule Storybook.Components.Tooltip do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Tooltip.tooltip/1
  def imports, do: [{CommonUI.Components.Icon, icon: 1}]

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          target_id: "foobar"
        },
        slots: [
          "This is a tooltip"
        ],
        template: """
        <div>
          <.icon name={:face_smile} class="size-5" id="foobar" />
          <.psb-variation />
        </div>
        """
      }
    ]
  end
end

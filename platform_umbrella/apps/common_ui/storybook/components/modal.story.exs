defmodule Storybook.Components.Modal do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Modal.modal/1
  def imports, do: [{CommonUI.Components.Button, button: 1}]

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: [
          "<:title>Title</:title>",
          "<p>This is a modal.</p>"
        ],
        template: """
        <div>
          <.button variant="primary" phx-click={Modal.show_modal("modal-single-default")}>
            Open Modal
          </.button>

          <.psb-variation/>
        </div>
        """
      },
      %Variation{
        id: :with_actions,
        attributes: %{},
        slots: [
          "<:title>Title</:title>",
          "<:actions cancel=\"Cancel\">",
          "  <.button variant=\"primary\">Confirm</.button>",
          "</:actions>",
          "<p>This is a modal.</p>"
        ],
        template: """
        <div>
          <.button variant="primary" phx-click={Modal.show_modal("modal-single-with-actions")}>
            Open Modal
          </.button>

          <.psb-variation/>
        </div>
        """
      }
    ]
  end
end

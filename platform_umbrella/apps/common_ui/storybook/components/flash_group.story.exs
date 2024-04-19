defmodule Storybook.Components.FlashGroup do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.FlashGroup.flash_group/1
  def imports, do: [{CommonUI.Components.Button, button: 1}]

  def variations do
    [
      %Variation{
        id: :inline,
        attributes: %{
          flash: %{
            "info" => "This is an info alert",
            "success" => "This is a success alert",
            "warning" => "This is a warning alert",
            "error" => "This is an error alert"
          }
        },
        template: """
        <.psb-variation class="mb-2" />
        """
      },
      %Variation{
        id: :global,
        attributes: %{
          global: true,
          flash: %{
            "global_info" => "This is an info alert",
            "global_success" => "This is a success alert",
            "global_warning" => "This is a warning alert",
            "global_error" => "This is an error alert"
          }
        },
        template: """
        <.button variant="minimal" phx-click={JS.show(to: "#flash-group-single-global")}>
          Show Alerts
        </.button>

        <.psb-variation class="hidden" />
        """
      }
    ]
  end
end

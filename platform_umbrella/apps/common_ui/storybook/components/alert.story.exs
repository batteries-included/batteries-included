defmodule Storybook.Components.Alert do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias CommonUI.Components.Alert

  def function, do: &Alert.alert/1
  def imports, do: [{CommonUI.Components.Button, button: 1}, {Alert, show_alert: 1}]

  def variations do
    [
      %Variation{
        id: :info,
        slots: ["Lorem ipsum dolor sit amet"]
      },
      %Variation{
        id: :success,
        slots: ["Lorem ipsum dolor sit amet"],
        attributes: %{
          variant: "success"
        }
      },
      %Variation{
        id: :warning,
        slots: ["Lorem ipsum dolor sit amet"],
        attributes: %{
          variant: "warning"
        }
      },
      %Variation{
        id: :error,
        slots: ["Lorem ipsum dolor sit amet"],
        attributes: %{
          variant: "error"
        }
      },
      %Variation{
        id: :fixed,
        slots: ["Lorem ipsum dolor sit amet"],
        attributes: %{
          type: "fixed",
          autoshow: false
        },
        template: """
        <.button variant="minimal" phx-click={show_alert("alert-single-fixed")}>
          Show Alert
        </.button>

        <.psb-variation class="hidden" />
        """
      },
      %Variation{
        id: :disconnected,
        slots: ["Lorem ipsum dolor sit amet"],
        attributes: %{
          type: "fixed",
          variant: "disconnected",
          autoshow: false
        },
        template: """
        <.button variant="minimal" phx-click={show_alert("alert-single-disconnected")}>
          Show Alert
        </.button>

        <.psb-variation class="hidden" />
        """
      }
    ]
  end
end

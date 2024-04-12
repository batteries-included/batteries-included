defmodule Storybook.Components.Loader do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Loader.loader/1
  def imports, do: [{CommonUI.Components.Button, button: 1}]

  def template do
    """
    <div class="p-12" psb-code-hidden>
      <.psb-variation />
    </div>
    """
  end

  def variations do
    [
      %Variation{id: :default},
      %Variation{
        id: :fullscreen,
        attributes: %{
          fullscreen: true
        },
        template: """
        <.button variant="primary" phx-click={JS.show(to: "#container")}>
          Open
        </.button>

        <div id="container" class="hidden" phx-click={JS.hide(to: "#container")}>
          <.psb-variation />
        </div>
        """
      }
    ]
  end
end

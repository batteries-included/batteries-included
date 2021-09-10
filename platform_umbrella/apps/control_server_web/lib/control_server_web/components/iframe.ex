defmodule ControlServerWeb.IFrame do
  use Surface.Component

  prop src, :string, required: true
  prop id, :string, default: "Main_IFrame"

  def render(assigns) do
    ~F"""
    <iframe {=@src} class="iframe-container" phx-hook="IFrame" {=@id} />
    """
  end
end

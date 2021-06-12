defmodule CommonUI.Button do
  use Surface.Component

  @doc "The content of the button"
  slot(default)

  @doc "Triggered on click"
  prop(click, :event)

  prop(class, :css_class, default: [])

  prop(phx_payload, :string, default: nil)

  def render(assigns) do
    ~F"""
    <button
      type="button"
      :on-click={@click}
      phx-value-payload={@phx_payload}
      class={[
        "inline-flex",
        "items-center",
        "px-4",
        "py-2",
        "border",
        "border-gray-300",
        "rounded-md",
        "shadow-sm",
        "text-base",
        "font-medium",
        "text-gray-700",
        "bg-white",
        "hover:bg-gray-50",
        "hover:border-pink-500",
        "focus:outline-none",
        "focus:ring-3",
        "focus:ring-opacity-80",
        "focus:ring-pink-500"
      ] ++ @class}
    >
      <#slot />
    </button>
    """
  end
end

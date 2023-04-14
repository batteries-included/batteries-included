defmodule CommonUI.Tooltip do
  use CommonUI.Component

  slot :inner_block, required: true
  slot :tooltip
  attr :class, :string, default: ""
  attr :rest, :global

  def hover_tooltip(%{tooltip: []} = assigns) do
    ~H"""
    <%= render_slot(@inner_block) %>
    """
  end

  def hover_tooltip(assigns) do
    ~H"""
    <div class={build_class(["group relative", @class])} {@rest}>
      <div
        class={
          build_class([
            "invisible group-hover:visible group-focus-within:visible",
            "absolute -translate-x-1 -translate-y-full",
            "rounded-md shadow-sm bg-pink-200 bg-opacity-95 p-2"
          ])
        }
        role="tooltip"
        aria-hidden="true"
      >
        <%= render_slot(@tooltip) %>
      </div>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end

defmodule CommonUI.Card do
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]
  import CommonUI.CSSHelpers

  slot :inner_block
  attr :class, :string, default: nil

  def card(assigns) do
    ~H"""
    <div class={
      build_class([
        "p-6",
        "bg-white rounded-lg",
        " border border-gray-200",
        "shadow-md dark:bg-gray-800 dark:border-gray-700",
        @class
      ])
    }>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end

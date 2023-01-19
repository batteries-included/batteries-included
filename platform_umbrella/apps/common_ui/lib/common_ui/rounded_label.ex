defmodule CommonUI.RoundedLabel do
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]
  import CommonUI.CSSHelpers

  attr(:class, :string, default: "")
  slot(:inner_block)

  def rounded_label(assigns) do
    ~H"""
    <div class={
      build_class([
        "text-xs font-bold leading-sm uppercase",
        "rounded-full border",
        "inline-flex items-center",
        "m-1 px-4 py-1",
        @class
      ])
    }>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end

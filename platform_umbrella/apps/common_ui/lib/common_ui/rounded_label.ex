defmodule CommonUI.RoundedLabel do
  @moduledoc false
  use CommonUI.Component

  attr :class, :string, default: ""
  slot :inner_block

  def rounded_label(assigns) do
    ~H"""
    <div class={[
      "text-xs font-bold leading-sm uppercase",
      "rounded-lg border",
      "shadow-md",
      "inline-flex items-center",
      "m-1 px-4 py-2",
      @class
    ]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end

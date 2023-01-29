defmodule ControlServerWeb.LeftMenuPage do
  use ControlServerWeb, :html

  slot(:inner_block, required: true)

  def body_section(assigns) do
    ~H"""
    <.card>
      <%= render_slot(@inner_block) %>
    </.card>
    """
  end

  slot(:inner_block, required: true)

  def section_title(assigns) do
    ~H"""
    <.h2 class="text-right">
      <%= render_slot(@inner_block) %>
    </.h2>
    """
  end
end

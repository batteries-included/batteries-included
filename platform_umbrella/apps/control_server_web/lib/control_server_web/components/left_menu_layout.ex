defmodule ControlServerWeb.LeftMenuLayout do
  use ControlServerWeb, :html

  import ControlServerWeb.MenuLayout

  defdelegate title(assigns), to: ControlServerWeb.MenuLayout

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

  attr(:group, :atom, default: :magic)
  attr(:active, :atom, default: :batteries)

  slot(:inner_block, required: true)
  slot(:title)

  def layout(assigns) do
    ~H"""
    <.menu_layout>
      <:title :if={@title != nil && @title != []}><%= render_slot(@title) %></:title>
      <div class="lg:grid lg:grid-cols-9 lg:gap-x-5">
        <aside class="py-6 px-2 sm:px-6 lg:py-0 lg:px-0 lg:col-span-2">
          <.live_component
            module={ControlServerWeb.LeftMenu}
            id="left"
            group={@group}
            active={@active}
          />
        </aside>
        <div class="space-y-6 sm:px-6 lg:px-0 lg:col-span-7">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </.menu_layout>
    """
  end
end

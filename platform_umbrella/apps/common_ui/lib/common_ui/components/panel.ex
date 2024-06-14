defmodule CommonUI.Components.Panel do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Container
  import CommonUI.Components.Typography

  attr :variant, :string, values: ["gray"]
  attr :class, :any, default: nil
  attr :inner_class, :any, default: nil
  attr :title, :string
  attr :rest, :global

  slot :menu
  slot :inner_block

  def panel(assigns) do
    ~H"""
    <div class={[panel_class(assigns[:variant]), @class]} {@rest}>
      <.flex :if={assigns[:title]} class="items-center justify-between flex-wrap w-full px-6 pt-5">
        <.h3><%= @title %></.h3>

        <%= if @menu, do: render_slot(@menu) %>
      </.flex>

      <div class={["relative flex-1 px-6 py-5", @inner_class]}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp panel_class("gray") do
    [
      "bg-gray-lightest rounded-lg dark:bg-gray-darker/20",
      panel_class()
    ]
  end

  defp panel_class(_) do
    [
      "bg-white border border-gray-lighter rounded-lg dark:bg-gray-darkest/70 dark:border-gray-darker",
      panel_class()
    ]
  end

  defp panel_class do
    "flex flex-col"
  end
end

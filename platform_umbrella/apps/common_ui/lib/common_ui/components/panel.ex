defmodule CommonUI.Components.Panel do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Container
  import CommonUI.Components.Typography

  attr :variant, :string, values: ["gray"]
  attr :class, :string, default: nil
  attr :title, :string
  attr :rest, :global

  slot :menu
  slot :inner_block

  def panel(assigns) do
    ~H"""
    <div class={[panel_class(assigns[:variant]), @class]} {@rest}>
      <.flex
        :if={assigns[:title]}
        class="items-center justify-between w-full text-center flex-col lg:flex-row px-6 py-5"
      >
        <.h3><%= @title %></.h3>

        <%= if @menu, do: render_slot(@menu) %>
      </.flex>

      <div class="px-6 py-5">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp panel_class("gray") do
    "bg-gray-lightest rounded-lg dark:bg-gray-darkest/50"
  end

  defp panel_class(_) do
    "bg-white border border-gray-lighter rounded-lg dark:bg-gray-darkest/70 dark:border-gray-darker"
  end
end

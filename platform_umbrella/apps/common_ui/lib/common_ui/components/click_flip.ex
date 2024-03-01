defmodule CommonUI.Components.ClickFlip do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Button
  import CommonUI.Components.Container
  import CommonUI.Components.Tooltip

  slot :inner_block
  slot :hidden

  attr :class, :any, default: nil
  attr :cursor_class, :any, default: "cursor-pointer"
  attr :content_class, :any, default: "min-w-10 py-4"

  attr :tooltip, :string, default: nil
  attr :id, :string, required: false, default: nil

  def click_flip(assigns) do
    ~H"""
    <.flex
      x-data="{ open: false }"
      {%{ "@keydown.escape.window" => "open = false"}}
      class={@class}
      id={@id}
    >
      <div
        class={[
          @cursor_class,
          @content_class,
          "border border-transparent border-dashed hover:border-gray-light dark:hover-border-gray-darkest",
          "rounded",
          "hover:bg-gray-lightest/70 dark:hover:bg-gray-darkest/70"
        ]}
        @click="open = !open"
        x-cloak
        x-show="!open"
        x-transition:enter="transition ease-out duration-100"
        x-transition:enter-start="transform opacity-0 scale-95"
        x-transition:enter-end="transform opacity-100 scale-100"
        id={content_id(@id)}
      >
        <%= render_slot(@inner_block) %>
        <.tooltip
          :if={@id != nil and @tooltip != nil}
          target_id={content_id(@id)}
          tippy_options={%{placement: "left"}}
        >
          Click to edit
        </.tooltip>
      </div>
      <.flex
        x-cloak
        x-show="open"
        x-transition:enter="transition ease-out duration-100"
        x-transition:enter-start="transform opacity-0 scale-95"
        x-transition:enter-end="transform opacity-100 scale-100"
        class="items-center py-4 -mt-5"
      >
        <%= render_slot(@hidden) %>
        <.button variant="icon" icon={:check} x-on:click="open = !open" />
      </.flex>
    </.flex>
    """
  end

  defp content_id(nil), do: nil
  defp content_id(id), do: "content_id_#{id}"
end

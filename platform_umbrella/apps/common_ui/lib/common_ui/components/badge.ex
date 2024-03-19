defmodule CommonUI.Components.Badge do
  @moduledoc false
  use CommonUI, :component

  attr :value, :any
  attr :label, :any, default: nil
  attr :rest, :global

  slot :item do
    attr :label, :any, required: true
  end

  def badge(%{value: _} = assigns) do
    ~H"""
    <div class={[badge_class(), "rounded-xl gap-3 px-6 py-3"]} {@rest}>
      <span class="text-2xl font-semibold"><%= @value %></span>
      <span><%= @label %></span>
    </div>
    """
  end

  def badge(assigns) do
    ~H"""
    <div
      class={[
        badge_class(),
        "rounded-lg divide-x divide-solid divide-gray-lighter dark:divide-gray-darker"
      ]}
      {@rest}
    >
      <%= for item <- @item do %>
        <div class="flex text-sm px-5 my-2 gap-1">
          <span class="text-gray"><%= item.label %>:</span>
          <span><%= render_slot(item) %></span>
        </div>
      <% end %>
    </div>
    """
  end

  def badge_class do
    [
      "flex flex-nowrap items-center whitespace-nowrap",
      "bg-white border border-1 border-gray-lighter text-gray-darkest",
      "dark:bg-gray-darkest dark:border-gray-darker dark:text-white"
    ]
  end
end

defmodule CommonUI.Components.Badge do
  @moduledoc false
  use CommonUI, :component

  attr :value, :any
  attr :label, :any, default: nil
  attr :minimal, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  slot :item do
    attr :label, :any, required: true
    attr :navigate, :string
    attr :patch, :string
    attr :href, :string
  end

  def badge(%{minimal: true} = assigns) do
    ~H"""
    <div class={[
      "bg-gray-lighter dark:bg-gray-darkest-tint text-xs text-white dark:text-gray-darker-tint font-semibold rounded px-1 py-0.5 whitespace-nowrap",
      @class
    ]}>
      {@label}
    </div>
    """
  end

  def badge(%{value: _} = assigns) do
    ~H"""
    <div class={["rounded-xl gap-3 px-3 py-2", badge_class(), @class]} {@rest}>
      <span class="text-2xl font-semibold">{@value}</span>
      <span>{@label}</span>
    </div>
    """
  end

  def badge(assigns) do
    ~H"""
    <div
      class={[
        "rounded-lg divide-x divide-solid divide-gray-lighter dark:divide-gray-darker",
        badge_class(),
        @class
      ]}
      {@rest}
    >
      <%= for item <- @item do %>
        <div class="flex text-sm px-5 my-2 gap-1">
          <span class="text-gray">{item.label}:</span>

          <%= if item[:navigate] || item[:patch] || item[:href] do %>
            <.link class="hover:underline" {assigns_to_attributes(item, [:label])}>
              {render_slot(item)}
            </.link>
          <% else %>
            <span>{render_slot(item)}</span>
          <% end %>
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

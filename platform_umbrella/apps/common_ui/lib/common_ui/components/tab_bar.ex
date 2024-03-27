defmodule CommonUI.Components.TabBar do
  @moduledoc false
  use CommonUI, :component

  attr :variant, :string, default: "primary", values: ["primary", "secondary", "borderless"]
  attr :class, :any, default: nil

  # Don't validate attributes or define the `attr` macro under slot,
  # since slots don't support the `:global` attribute and we need to
  # pass phx bindings.
  slot :tab, validate_attrs: false

  def tab_bar(assigns) do
    ~H"""
    <div aria-label="Tabs" class={[tab_bar_class(assigns[:variant]), @class]}>
      <%= for tab <- @tab do %>
        <.link
          class={tab_class(assigns[:variant], Map.get(tab, :selected, false))}
          {assigns_to_attributes(tab, [:selected])}
        >
          <%= render_slot(tab) %>
        </.link>
      <% end %>
    </div>
    """
  end

  defp tab_bar_class("primary") do
    [
      "bg-white dark:bg-gray-darkest-tint border border-gray-lighter dark:border-gray-darker-tint",
      tab_bar_class()
    ]
  end

  defp tab_bar_class("secondary") do
    [
      "bg-gray-lightest dark:bg-gray-darkest-tint border border-gray-lighter dark:border-gray-darker-tint",
      tab_bar_class()
    ]
  end

  defp tab_bar_class("borderless") do
    [
      "bg-white dark:bg-gray-darkest-tint p-1",
      tab_bar_class()
    ]
  end

  defp tab_bar_class do
    "flex rounded-lg font-semibold text-sm text-gray-darkest dark:text-gray"
  end

  defp tab_class("primary", true) do
    [
      "text-white bg-primary ring-primary",
      tab_class()
    ]
  end

  defp tab_class("primary", false) do
    [
      "ring-transparent hover:text-primary",
      tab_class()
    ]
  end

  defp tab_class("secondary", true) do
    [
      "bg-white dark:bg-gray-darker text-primary ring-primary",
      tab_class()
    ]
  end

  defp tab_class("secondary", false) do
    [
      "ring-transparent hover:text-primary",
      tab_class()
    ]
  end

  defp tab_class("borderless", true) do
    [
      "text-white bg-primary ring-primary",
      tab_class()
    ]
  end

  defp tab_class("borderless", false) do
    [
      "ring-transparent hover:text-primary",
      tab_class()
    ]
  end

  defp tab_class do
    "flex-1 px-5 py-3 text-center rounded-lg cursor-pointer ring-1"
  end
end

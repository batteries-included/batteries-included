defmodule CommonUI.Components.TabBar do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Icon

  attr :variant, :string, default: "primary", values: ["primary", "secondary", "borderless", "navigation", "minimal"]
  attr :class, :any, default: nil

  # Don't validate attributes or define the `attr` macro under slot,
  # since slots don't support the `:global` attribute and we need to
  # pass phx bindings.
  slot :tab, validate_attrs: false

  def tab_bar(%{variant: "minimal"} = assigns) do
    ~H"""
    <div class={[
      "border-b border-gray-lighter dark:border-gray-darker-tint",
      @class
    ]}>
      <nav aria-label="Tabs" class="-mb-px flex space-x-8">
        <%= for tab <- @tab do %>
          <.link
            {assigns_to_attributes(tab, [:icon, :selected])}
            class={[
              "group inline-flex items-center border-b-2 px-1 py-4 text-sm font-medium cursor-pointer",
              tab_class("minimal", Map.get(tab, :selected))
            ]}
          >
            <.icon :if={icon = Map.get(tab, :icon)} name={icon} class="mr-2 -ml-0.5 size-5" />
            <span>{render_slot(tab)}</span>
          </.link>
        <% end %>
      </nav>
    </div>
    """
  end

  def tab_bar(assigns) do
    ~H"""
    <div class={[
      "flex rounded-lg",
      tab_bar_class(assigns[:variant]),
      @class
    ]}>
      <%= for tab <- @tab do %>
        <.link
          {assigns_to_attributes(tab, [:icon, :selected])}
          class={[
            "flex items-center gap-3 px-5 py-3 rounded-lg cursor-pointer",
            tab_class(assigns[:variant], Map.get(tab, :selected))
          ]}
        >
          <.icon :if={icon = Map.get(tab, :icon)} name={icon} class="size-6" />
          <span>{render_slot(tab)}</span>
        </.link>
      <% end %>
    </div>
    """
  end

  defp tab_bar_class("primary") do
    "bg-white dark:bg-gray-darkest-tint border border-gray-lighter dark:border-gray-darker-tint"
  end

  defp tab_bar_class("secondary") do
    "bg-gray-lightest dark:bg-gray-darkest-tint border border-gray-lighter dark:border-gray-darker-tint"
  end

  defp tab_bar_class("borderless") do
    "bg-white dark:bg-gray-darkest-tint p-1"
  end

  defp tab_bar_class("navigation") do
    "flex-col gap-3"
  end

  defp tab_class do
    "flex-1 justify-center font-semibold whitespace-nowrap text-sm text-gray-darkest dark:text-gray hover:text-primary"
  end

  defp tab_class("primary", selected) do
    [
      tab_class(),
      selected && "bg-primary ring-1 ring-primary text-white dark:text-white hover:text-white"
    ]
  end

  defp tab_class("secondary", selected) do
    [
      tab_class(),
      selected && "bg-white dark:bg-gray-darker ring-1 ring-primary text-primary dark:text-primary hover:text-primary"
    ]
  end

  defp tab_class("borderless", selected) do
    [
      tab_class(),
      selected && "bg-primary text-white dark:text-white hover:text-white"
    ]
  end

  defp tab_class("navigation", selected) do
    [
      "hover:bg-white dark:hover:bg-gray-darkest hover:drop-shadow-md font-medium text-gray-dark dark:text-gray",
      selected &&
        "bg-white dark:bg-gray-darkest drop-shadow-md text-gray-darkest dark:text-white [&>svg]:text-primary",
      # Prevents weirdness with drop shadow in safari
      "transform-gpu"
    ]
  end

  defp tab_class("minimal", true) do
    "border-primary text-primary dark:text-primary hover:text-primary [&>svg]:text-primary dark:[&>svg]:text-primary"
  end

  defp tab_class("minimal", _) do
    "border-transparent text-gray-dark dark:text-gray hover:border-gray-light dark:hover:border-gray-darker-tint hover:text-gray-darkest dark:hover:text-gray-light [&>svg]:text-gray [&>svg]:group-hover:text-gray-dark dark:[&>svg]:text-gray-dark dark:[&>svg]:group-hover:text-gray"
  end
end

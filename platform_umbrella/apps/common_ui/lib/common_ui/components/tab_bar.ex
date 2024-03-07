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

  defp tab_bar_class("primary"), do: tab_bar_class() <> " bg-white border border-gray-lighter"
  defp tab_bar_class("secondary"), do: tab_bar_class() <> " bg-gray-lightest border border-gray-lighter"
  defp tab_bar_class("borderless"), do: tab_bar_class() <> " bg-white p-1"
  defp tab_bar_class, do: "flex rounded-lg font-semibold text-sm text-gray-darkest"

  defp tab_class("primary", true), do: tab_class() <> " text-white bg-primary ring-primary"
  defp tab_class("primary", false), do: tab_class() <> " ring-transparent hover:text-primary"
  defp tab_class("secondary", true), do: tab_class() <> " bg-white text-primary ring-primary"
  defp tab_class("secondary", false), do: tab_class() <> " ring-transparent hover:text-primary"
  defp tab_class("borderless", true), do: tab_class() <> " text-white bg-primary ring-primary"
  defp tab_class("borderless", false), do: tab_class() <> " ring-transparent hover:text-primary"
  defp tab_class, do: "flex-1 px-5 py-3 text-center rounded-lg cursor-pointer ring-1"
end

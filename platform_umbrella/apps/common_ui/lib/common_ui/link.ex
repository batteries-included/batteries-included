defmodule CommonUI.Link do
  @moduledoc false
  use Phoenix.Component

  attr :variant, :string, default: "unstyled", values: ["icon", "styled", "external", "unstyled"]
  attr :icon, :atom, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(download hreflang replace referrerpolicy rel target type href navigate patch)

  slot :inner_block, required: true

  def a(%{variant: "icon"} = assigns) do
    ~H"""
    <.link class={[link_class(@variant), "flex items-center", @class]} {@rest}>
      <PC.icon :if={@icon} name={@icon} class="w-5 h-5 mr-2" />
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  def a(%{variant: "external"} = assigns) do
    ~H"""
    <.link class={[link_class(@variant), @class]} target="_blank" {@rest}>
      <span class="flex-initial">
        <%= render_slot(@inner_block) %>
      </span>
      <Heroicons.arrow_top_right_on_square class="ml-2 w-5 h-5 flex-none" />
    </.link>
    """
  end

  def a(assigns) do
    ~H"""
    <.link class={[link_class(@variant), @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp link_class("icon" = _variant), do: "font-medium text-pink-500 hover:text-pink-600 hover:opacity-50"
  defp link_class("styled" = _variant), do: "font-medium text-pink-500 hover:text-pink-600 hover:underline"
  defp link_class("external" = _variant), do: "font-medium text-pink-600 hover:underline flex"
  defp link_class(_variant), do: ""
end

defmodule CommonUI.Components.Link do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Icon

  attr :variant, :string, values: ["underlined", "icon", "external", "bordered"]
  attr :icon, :atom, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(download hreflang replace referrerpolicy rel target type href navigate patch method)

  slot :inner_block, required: true

  def a(%{variant: "icon"} = assigns) do
    ~H"""
    <.link class={[link_class(@variant), "flex items-center", @class]} {@rest}>
      <.icon :if={@icon} name={@icon} class="w-5 h-5 mr-2" />
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  def a(%{variant: "external"} = assigns) do
    ~H"""
    <.link class={[link_class(@variant), @class]} target="_blank" {@rest}>
      <span class="flex-initial"><%= render_slot(@inner_block) %></span>
      <.icon name={:arrow_top_right_on_square} class="ml-2 w-5 h-5 flex-none" />
    </.link>
    """
  end

  def a(%{variant: "bordered"} = assigns) do
    assigns =
      case Map.get(assigns.rest, :href) do
        nil ->
          assign(assigns, :icon, :arrow_right)

        _ ->
          assigns
          |> assign(:icon, :arrow_top_right_on_square)
          |> assign(:rest, Map.put(assigns.rest, :target, "_blank"))
      end

    ~H"""
    <.link class={[link_class(@variant), @class]} {@rest}>
      <span class="font-medium"><%= render_slot(@inner_block) %></span>
      <.icon name={@icon} class="w-5 h-5 text-primary my-auto" />
    </.link>
    """
  end

  def a(assigns) do
    ~H"""
    <.link class={[link_class(assigns[:variant]), @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp link_class("underlined"), do: "underline hover:opacity-75"
  defp link_class("icon"), do: "font-medium text-primary hover:text-primary-dark hover:opacity-50"
  defp link_class("external"), do: "font-medium text-primary-dark hover:underline flex"

  defp link_class("bordered") do
    [
      "flex items-center gap-4 justify-between px-4 py-3 border rounded-lg",
      "border-gray-lighter dark:border-gray-darker hover:border-primary"
    ]
  end

  defp link_class(_), do: "font-medium text-primary hover:text-primary-dark hover:underline"
end

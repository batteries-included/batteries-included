defmodule CommonUI.Page do
  @moduledoc false
  use CommonUI.Component

  import CommonUI.Container
  import CommonUI.Typography

  attr :title, :string, required: true
  attr :navigate, :string, required: false
  attr :patch, :string, required: false

  slot :inner_block, required: true

  defp pill_menu_item(%{patch: patch} = assigns) when patch != nil do
    ~H"""
    <.a patch={@patch} class="grow">
      <.flex class="p-4 border border-gray-200 dark:border-gray-600 rounded-xl">
        <.h5><%= @title %></.h5>
        <div class="font-semibold grow"><%= render_slot(@inner_block) %></div>
        <PC.icon name={:arrow_right} class="w-5 h-5 text-primary-500 my-auto" />
      </.flex>
    </.a>
    """
  end

  defp pill_menu_item(assigns) do
    ~H"""
    <.a navigate={@navigate} class="grow">
      <.flex class="p-4 border border-gray-200 dark:border-gray-600 rounded-xl">
        <.h5><%= @title %></.h5>
        <div class="font-semibold grow"><%= render_slot(@inner_block) %></div>
        <PC.icon name={:arrow_right} class="w-5 h-5 text-primary-500 my-auto" />
      </.flex>
    </.a>
    """
  end

  attr :class, :string, default: ""

  slot :item, required: true do
    attr :title, :string, required: true
    attr :navigate, :string, required: false
    attr :patch, :string, required: false
  end

  @spec pills_menu(map()) :: Phoenix.LiveView.Rendered.t()
  def pills_menu(assigns) do
    ~H"""
    <.flex class={["my-4 text-gray-700 dark:text-white text-lg", @class]}>
      <.pill_menu_item
        :for={item <- @item}
        title={item[:title]}
        navigate={item[:navigate]}
        patch={item[:patch]}
      >
        <%= render_slot(item) %>
      </.pill_menu_item>
    </.flex>
    """
  end
end

defmodule CommonUI.TabBar do
  @moduledoc false
  use CommonUI.Component

  import CommonUI.Container

  defp link_class_base,
    do: "group relative min-w-0 flex-1 overflow-hidden py-3 px-4 text-sm font-medium text-center focus:z-10 rounded-lg"

  defp link_class(false),
    do: link_class_base() <> " text-gray-700 hover:bg-gray-100 dark:hover:bg-gray-700 dark:text-gray-300 p-4"

  defp link_class(true), do: link_class_base() <> " text-white rounded-l-lg bg-primary-500"

  defp decoration_class(false), do: "bg-transparent absolute inset-x-0 bottom-0 h-0.5"
  defp decoration_class(true), do: "bg-pink-500 absolute inset-x-0 bottom-0 h-0.5"

  attr :tabs, :any, default: nil
  attr :class, :any, default: nil
  slot :inner_block, required: false

  def tab_bar(assigns) do
    ~H"""
    <div class={["pb-6", @class]}>
      <.flex
        class={[
          "isolate",
          "rounded-lg",
          "border-gray-200 dark:bg-gray-800 dark:border-gray-600 border",
          "flex-col mx-5",
          "lg:flex-row lg:mx-0",
          @class
        ]}
        aria-label="Tabs"
      >
        <%= render_slot(@inner_block) %>
      </.flex>
    </div>
    """
  end

  attr :navigate, :any, default: nil
  attr :patch, :any, default: nil
  attr :selected, :boolean, default: false
  attr :rest, :global

  slot :inner_block, required: true

  def tab_item(%{navigate: nav} = assigns) when nav != nil do
    ~H"""
    <.a navigate={@navigate} class={link_class(@selected)} {@rest}>
      <span><%= render_slot(@inner_block) %></span>
      <span aria-hidden="true" class={decoration_class(@selected)}></span>
    </.a>
    """
  end

  def tab_item(%{patch: p} = assigns) when p != nil do
    ~H"""
    <.a patch={@patch} class={link_class(@selected)} {@rest}>
      <span><%= render_slot(@inner_block) %></span>
      <span aria-hidden="true" class={decoration_class(@selected)}></span>
    </.a>
    """
  end

  def tab_item(assigns) do
    ~H"""
    <.a class={link_class(@selected)} {@rest}>
      <span><%= render_slot(@inner_block) %></span>
      <span aria-hidden="true" class={decoration_class(@selected)}></span>
    </.a>
    """
  end
end

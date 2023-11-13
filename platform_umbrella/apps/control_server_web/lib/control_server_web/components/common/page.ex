defmodule ControlServerWeb.Common.Page do
  @moduledoc false
  use Phoenix.Component

  import CommonUI.Container
  import CommonUI.Link
  import CommonUI.Typography

  attr :title, :string

  attr :back_button, :map,
    default: nil,
    doc: ~s|Attributes for the back link, if it exists. eg. back_button={%{link_type="live_redirect" to="/"}}|

  slot :right_side

  def page_header(assigns) do
    ~H"""
    <.flex class="items-center justify-between mb-6">
      <.flex class="flex items-center gap-4">
        <PC.a
          :if={@back_button}
          {@back_button}
          class="inline-block p-1.5 border border-gray-300 rounded-lg border-1 dark:border-gray-600"
        >
          <Heroicons.arrow_left class="w-4 h-4 stroke-[3] text-primary-500 fill-primary-500 dark:text-primary-300 dark:fill-primary-300" />
        </PC.a>
        <.flex class="items-center">
          <.h3 class="text-2xl font-medium text-black dark:text-white">
            <%= @title %>
          </.h3>
        </.flex>
      </.flex>

      <%= if render_slot(@right_side) do %>
        <%= render_slot(@right_side) %>
      <% end %>
    </.flex>
    """
  end

  attr :title, :string, required: false
  attr :navigate, :string, required: false
  attr :patch, :string, required: true

  slot :inner_block, required: false

  defp pill_menu_item(%{patch: patch} = assigns) when patch != nil do
    ~H"""
    <.a patch={@patch} class="grow">
      <.flex class="p-4 border border-gray-200 dark:border-gray-600 rounded-xl">
        <.h5 :if={@title != nil}><%= @title %></.h5>
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
        <.h5 :if={@title != nil}><%= @title %></.h5>
        <div class="font-semibold grow">
          <%= render_slot(@inner_block) %>
        </div>
        <PC.icon name={:arrow_right} class="w-5 h-5 text-primary-500 my-auto" />
      </.flex>
    </.a>
    """
  end

  attr :class, :string, default: ""

  slot :item, required: true do
    attr :title, :string, required: false
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

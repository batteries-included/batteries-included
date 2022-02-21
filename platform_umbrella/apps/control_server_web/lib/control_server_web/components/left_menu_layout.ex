defmodule ControlServerWeb.LeftMenuLayout do
  use Phoenix.Component
  use PetalComponents

  alias CommonUI.Icons.Notebook
  alias ControlServerWeb.Layout

  @default_icon_class "group-hover:text-gray-500 flex-shrink-0 flex-shrink-0 -ml-1 mr-3 h-6 w-6 group"

  defp assign_defaults(assigns) do
    assigns
    |> assign_new(:title, fn -> [] end)
    |> assign_new(:inner_block, fn -> [] end)
    |> assign_new(:left_menu, fn -> [] end)
  end

  defp assign_menu_defaults(assigns) do
    assigns
    |> assign_new(:is_active, fn -> false end)
    |> assign_new(:icon, fn -> "database" end)
  end

  def left_menu_item(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
    <.link link_type="live_patch" to={@to} class={menu_link_class(@is_active)}>
      <.left_icon type={@icon} />
      <span class="truncate">
        <%= @name %>
      </span>
    </.link>
    """
  end

  defp left_icon(assigns) do
    assigns = assign_new(assigns, :class, fn -> @default_icon_class end)

    ~H"""
    <%= case @type do %>
      <% "notebooks" -> %>
        <Notebook.render class={@class} />
      <% "home" -> %>
        <Heroicons.Solid.home class={@class} />
      <% "database" -> %>
        <Heroicons.Solid.database class={@class} />
      <% "lightning_bolt" -> %>
        <Heroicons.Solid.lightning_bolt class={@class} />
      <% "status_online" -> %>
        <Heroicons.Solid.status_online class={@class} />
      <% "external_link" -> %>
        <Heroicons.Solid.external_link class={@class} />
    <% end %>
    """
  end

  defp menu_link_class(true = _active),
    do:
      "text-pink-600 hover:bg-white group rounded-md px-3 py-2 flex items-center text-sm font-medium"

  defp menu_link_class(_active),
    do:
      "text-gray-600 hover:text-gray-900 hover:bg-astral-100 group rounded-md px-3 py-2 flex items-center text-sm font-medium"

  defdelegate title(assigns), to: Layout

  def body_section(assigns) do
    ~H"""
    <div class="shadow sm:rounded-md sm:overflow-hidden">
      <div class="bg-white py-6 px-4 space-y-6 sm:p-6">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  def layout(assigns) do
    assigns = assign_defaults(assigns)

    ~H"""
    <Layout.layout>
      <:title>
        <%= render_slot(@title) %>
      </:title>
      <div class="lg:grid lg:grid-cols-12 lg:gap-x-5">
        <aside class="py-6 px-2 sm:px-6 lg:py-0 lg:px-0 lg:col-span-3">
          <nav class="space-y-1">
            <%= render_slot(@left_menu) %>
          </nav>
        </aside>
        <div class="space-y-6 sm:px-6 lg:px-0 lg:col-span-9">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </Layout.layout>
    """
  end
end

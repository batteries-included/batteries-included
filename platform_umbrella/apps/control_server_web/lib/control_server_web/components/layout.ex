defmodule ControlServerWeb.Layout do
  use ControlServerWeb, :component

  import CommonUI.Icons.Devtools
  import CommonUI.Icons.Network

  alias CommonUI.Layout, as: BaseLayout
  alias ControlServerWeb.Endpoint

  defdelegate title(assigns), to: BaseLayout

  attr :class, :string,
    default: "pt-1 text-sm font-medium hover:bg-astral-100 hover:text-pink-500 text-gray-500"

  attr :navigate, :string, required: true
  attr :name, :string, required: true

  slot :inner_block

  def menu_item(assigns) do
    ~H"""
    <BaseLayout.menu_item navigate={@navigate} name={@name} class={@class}>
      <%= render_slot(@inner_block) %>
    </BaseLayout.menu_item>
    """
  end

  attr :icon_class, :string, default: "h-6 w-6 text-astral-500 group-hover:text-pink-500"
  attr :container_type, :any, default: :default
  attr :group, :any, default: :magic

  slot :inner_block
  slot :title

  def layout(assigns) do
    ~H"""
    <BaseLayout.layout bg_class="bg-white" container_type={@container_type}>
      <:title :if={@title != nil && @title != []}><%= render_slot(@title) %></:title>
      <:main_menu>
        <.menu_item navigate={Routes.group_batteries_path(Endpoint, :data)} name="Data">
          <Heroicons.circle_stack class={@icon_class} />
        </.menu_item>
        <.menu_item navigate={Routes.group_batteries_path(Endpoint, :ml)} name="ML">
          <Heroicons.beaker class={@icon_class} />
        </.menu_item>
        <.menu_item navigate={Routes.group_batteries_path(Endpoint, :monitoring)} name="Monitoring">
          <Heroicons.chart_bar class={@icon_class} />
        </.menu_item>
        <.menu_item navigate={Routes.group_batteries_path(Endpoint, :devtools)} name="Devtools">
          <.devtools_icon class={@icon_class} />
        </.menu_item>
        <.menu_item navigate={Routes.group_batteries_path(Endpoint, :net_sec)} name="Net/Security">
          <.net_sec_icon class={@icon_class} />
        </.menu_item>
        <.menu_item navigate={Routes.resource_list_path(Endpoint, :pod)} name="Magic">
          <Heroicons.sparkles class={@icon_class} />
        </.menu_item>
      </:main_menu>
      <%= render_slot(@inner_block) %>
    </BaseLayout.layout>
    """
  end
end

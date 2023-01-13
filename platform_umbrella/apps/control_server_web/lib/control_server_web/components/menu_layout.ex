defmodule ControlServerWeb.MenuLayout do
  use ControlServerWeb, :html

  import CommonUI.Icons.Devtools
  import CommonUI.Icons.Network
  import CommonUI.Icons.Batteries

  @default_container_class "flex-1 max-w-full sm:px-6 lg:px-8 pt-10 pb-16"
  @iframe_container_class "flex-1 pb-16 pt-0 px-0"

  defp container_class(:iframe), do: @iframe_container_class

  defp container_class(:default) do
    @default_container_class
  end

  slot(:inner_block, required: true)

  def title(assigns) do
    ~H"""
    <.h1 class="my-auto ml-3">
      <%= render_slot(@inner_block) %>
    </.h1>
    """
  end

  attr(:navigate, :string, required: true)
  slot(:label, required: true)
  slot(:inner_block, required: true)

  def menu_item(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class={[
        "pt-1 text-sm font-medium text-astral-800",
        "text-mono",
        "hover:bg-pink-50/50 hover:text-pink-500",
        "flex h-full w-full items-center flex-col justify-center"
      ]}
    >
      <%= render_slot(@inner_block) %>
      <span class="mt-1">
        <%= render_slot(@label) %>
      </span>
    </.link>
    """
  end

  attr(:icon_class, :string, default: "h-6 w-6 text-astral-700 group-hover:text-pink-500")
  attr(:container_type, :atom, default: :default)
  attr(:group, :atom, default: :magic)

  slot(:inner_block)
  slot(:title)

  def menu_layout(assigns) do
    ~H"""
    <div class="flex flex-col min-h-screen justify-between bg-gray-50 pb-18 overflow-auto">
      <header class="w-full bg-white h-16">
        <div class="flex max-w-full h-full">
          <.link navigate={~p"/"} class="my-auto mx-5">
            <.batteries_logo />
          </.link>
          <%= if @title do %>
            <%= render_slot(@title) %>
          <% end %>
          <h2 class="flex-grow px-5 text-3xl text-right text-astral-800 my-auto mx-6">
            Batteries Included
          </h2>
        </div>
      </header>
      <div class={container_class(@container_type)}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    <footer class="h-16 text-current fixed bottom-0 inset-x-0 flex justify-around items-center bg-white">
      <.menu_item navigate={~p"/system_projects"}>
        <:label>Projects</:label>
        <Heroicons.briefcase class={@icon_class} />
      </.menu_item>
      <.menu_item navigate={~p"/batteries/data"}>
        <:label>Data</:label>
        <Heroicons.circle_stack class={@icon_class} />
      </.menu_item>
      <.menu_item navigate={~p"/batteries/ml"}>
        <:label>ML</:label>
        <Heroicons.beaker class={@icon_class} />
      </.menu_item>
      <.menu_item navigate={~p"/batteries/monitoring"}>
        <:label>Monitoring</:label>
        <Heroicons.chart_bar class={@icon_class} />
      </.menu_item>
      <.menu_item navigate={~p"/batteries/devtools"}>
        <:label>Devtools</:label>
        <.devtools_icon class={@icon_class} />
      </.menu_item>
      <.menu_item navigate={~p"/batteries/net_sec"}>
        <:label>Net/Security</:label>
        <.net_sec_icon class={@icon_class} />
      </.menu_item>
      <.menu_item navigate={~p"/snapshot_apply"}>
        <:label>Magic</:label>
        <Heroicons.sparkles class={@icon_class} />
      </.menu_item>
    </footer>
    """
  end
end

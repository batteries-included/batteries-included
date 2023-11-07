defmodule HomeBaseWeb.TopMenuLayout do
  @moduledoc false
  use HomeBaseWeb, :html

  import CommonUI.CSSHelpers
  import CommonUI.Icons.Batteries

  @main_menu_items [
    %{title: "Dashboard", url: "/", id: :home},
    %{title: "Installations", url: "/installations", id: :installations}
  ]

  attr :title, :string, default: "Batteries Included"
  attr :page, :atom, default: :home
  attr :main_menu_items, :any, default: @main_menu_items

  slot :inner_block

  def top_menu_layout(assigns) do
    ~H"""
    <div class="min-h-full">
      <div class="bg-gray-800 pb-32">
        <nav class="bg-gray-800">
          <div class="mx-auto max-w-7xl sm:px-6 lg:px-8">
            <div class="border-b border-gray-700">
              <div class="flex h-16 items-center justify-between px-4 sm:px-0">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <.a navigate="/">
                      <.batteries_logo top_cloud_class="fill-pink-500" />
                    </.a>
                  </div>
                  <.main_menu menu_items={@main_menu_items} page={@page} />
                </div>
                <%!-- <.user_menu /> --%>
                <%!-- <.mobile_menu_show_hide /> --%>
              </div>
            </div>
          </div>
          <%!-- <.mobile_menu /> --%>
        </nav>
        <header class="py-10">
          <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <h1 class="text-3xl font-bold tracking-tight text-white"><%= @title %></h1>
          </div>
        </header>
      </div>

      <main class="-mt-32">
        <div class="mx-auto max-w-7xl px-4 pb-12 sm:px-6 lg:px-8">
          <div class="rounded-lg bg-white px-5 py-6 shadow sm:px-6 min-h-[32rem]">
            <%= render_slot(@inner_block) %>
          </div>
        </div>
      </main>
    </div>
    """
  end

  attr :menu_items, :any, required: true
  attr :page, :atom, required: true

  defp main_menu(assigns) do
    ~H"""
    <div class="hidden md:block">
      <div class="ml-10 flex items-baseline space-x-4">
        <!-- Current: "bg-gray-900 text-white", Default: "text-gray-300 hover:bg-gray-700 hover:text-white" -->
        <.a
          :for={menu_item <- @menu_items}
          navigate={menu_item.url}
          variant="unstyled"
          class={
            build_class([
              "px-3 py-2 text-sm font-medium",
              {"text-gray-300 hover:bg-gray-700 hover:text-white border-b-2 border-transparent hover:border-pink-500",
               menu_item.id != @page},
              {"border-t-2 border-pink-500 text-white", menu_item.id == @page}
            ])
          }
        >
          <%= menu_item.title %>
        </.a>
      </div>
    </div>
    """
  end
end

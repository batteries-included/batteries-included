defmodule ControlServerWeb.Layouts do
  use ControlServerWeb, :html

  import ControlServerWeb.LeftMenu
  import CommonUI.Icons.Batteries

  embed_templates("layouts/*")

  def fresh(assigns) do
    ~H"""
    <div
      class="fresh-container flex bg-gray-50 h-full w-full min-h-screen"
      x-data="{'menuOpen': true}"
    >
      <header class="navbar h-20 fixed bg-base-100 shadow-lg p-6">
        <div class="flex-none">
          <button
            class="inline-flex hover:text-pink-500 transition-none"
            x-on:click="menuOpen = ! menuOpen"
          >
            <Heroicons.bars_3_bottom_right class="inline-block h-8 w-auto stroke-current" />
          </button>
        </div>
        <div class="flex-1">
          <.link
            class="inline-flex normal-case text-xl transition-none animation-none m-4 justify-center"
            navigate={~p|/|}
          >
            <.batteries_logo class="h-10 w-auto mr-6" />
            <span class="align-middle my-auto">Batteries Included</span>
          </.link>
        </div>
      </header>

      <.left_menu
        x-show="menuOpen"
        x-cloak
        x-transition
        installed_batteries={Map.get(assigns, :installed_batteries, [])}
        page_group={Map.get(assigns, :page_group, nil)}
        page_detail_type={Map.get(assigns, :page_detail_type, nil)}
      />

      <main class="flex-auto relative p-6 space-y-4 sm:space-y-8">
        <%= @inner_content %>
      </main>
    </div>
    """
  end
end

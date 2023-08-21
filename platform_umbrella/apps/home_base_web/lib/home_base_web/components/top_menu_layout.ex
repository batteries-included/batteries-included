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

  # defp user_menu(assigns) do
  #   ~H"""
  #   <div class="hidden md:block">
  #     <div class="ml-4 flex items-center md:ml-6">
  #       <!-- Profile dropdown -->
  #       <div class="relative ml-3">
  #         <div>
  #           <button
  #             type="button"
  #             class={["flex max-w-xs items-center rounded-full bg-gray-800 text-sm",
  #                     "focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2",
  #                     "focus:ring-offset-gray-800"]}
  #             id="user-menu-button"
  #             aria-expanded="false"
  #             aria-haspopup="true"
  #           >
  #             <span class="sr-only">Open user menu</span>
  #             <img
  #               class="h-8 w-8 rounded-full"
  #               src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e"
  #               alt=""
  #             />
  #           </button>
  #         </div>
  #         <!--
  #                   Dropdown menu, show/hide based on menu state.

  #                   Entering: "transition ease-out duration-100"
  #                     From: "transform opacity-0 scale-95"
  #                     To: "transform opacity-100 scale-100"
  #                   Leaving: "transition ease-in duration-75"
  #                     From: "transform opacity-100 scale-100"
  #                     To: "transform opacity-0 scale-95"
  #                 -->
  #         <div
  #           class={["absolute right-0 z-10 mt-2 w-48 origin-top-right rounded-md bg-white",
  #                   "py-1 shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"]}
  #           role="menu"
  #           aria-orientation="vertical"
  #           aria-labelledby="user-menu-button"
  #           tabindex="-1"
  #         >
  #           <!-- Active: "bg-gray-100", Not Active: "" -->
  #           <a
  #             href="#"
  #             class="block px-4 py-2 text-sm text-gray-700"
  #             role="menuitem"
  #             tabindex="-1"
  #             id="user-menu-item-0"
  #           >
  #             Your Profile
  #           </a>

  #           <a
  #             href="#"
  #             class="block px-4 py-2 text-sm text-gray-700"
  #             role="menuitem"
  #             tabindex="-1"
  #             id="user-menu-item-1"
  #           >
  #             Settings
  #           </a>

  #           <a
  #             href="#"
  #             class="block px-4 py-2 text-sm text-gray-700"
  #             role="menuitem"
  #             tabindex="-1"
  #             id="user-menu-item-2"
  #           >
  #             Sign out
  #           </a>
  #         </div>
  #       </div>
  #     </div>
  #   </div>
  #   """
  # end

  # defp mobile_menu(assigns) do
  #   ~H"""
  #   <!-- Mobile menu, show/hide based on menu state. -->
  #   <div class="border-b border-gray-700 md:hidden" id="mobile-menu">
  #     <div class="space-y-1 px-2 py-3 sm:px-3">
  #       <!-- Current: "bg-gray-900 text-white", Default: "text-gray-300 hover:bg-gray-700 hover:text-white" -->
  #       <a
  #         href="#"
  #         class="bg-gray-900 text-white block px-3 py-2 rounded-md text-base font-medium"
  #         aria-current="page"
  #       >
  #         Dashboard
  #       </a>

  #       <a
  #         href="#"
  #         class={["text-gray-300 hover:bg-gray-700 hover:text-white",
  # .              "block px-3 py-2 rounded-md text-base font-medium"]}
  #       >
  #         Team
  #       </a>

  #     </div>
  #     <div class="border-t border-gray-700 pt-4 pb-3">
  #       <div class="flex items-center px-5">
  #         <div class="flex-shrink-0">
  #           <img
  #             class="h-10 w-10 rounded-full"
  #             src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e"
  #             alt=""
  #           />
  #         </div>
  #         <div class="ml-3">
  #           <div class="text-base font-medium leading-none text-white">Tom Cook</div>
  #           <div class="text-sm font-medium leading-none text-gray-400">tom@example.com</div>
  #         </div>
  #       </div>
  #       <div class="mt-3 space-y-1 px-2">
  #         <a
  #           href="#"
  #           class={["block rounded-md px-3 py-2 text-base font-medium",
  #                   "text-gray-400 hover:bg-gray-700 hover:text-white"]}
  #         >
  #           Your Profile
  #         </a>

  #         <a
  #           href="#"
  #           class={["block rounded-md px-3 py-2 text-base font-medium",
  #                   "text-gray-400 hover:bg-gray-700 hover:text-white"]}
  #         >
  #           Settings
  #         </a>

  #         <a
  #           href="#"
  #           class={["block rounded-md px-3 py-2 text-base font-medium",
  #                   "text-gray-400 hover:bg-gray-700 hover:text-white"]}
  #         >
  #           Sign out
  #         </a>
  #       </div>
  #     </div>
  #   </div>
  #   """
  # end

  # defp mobile_menu_show_hide(assigns) do
  #   ~H"""
  #   <div class="-mr-2 flex md:hidden">
  #     <!-- Mobile menu button -->
  #     <button
  #       type="button"
  #       class={["inline-flex items-center justify-center rounded-md",
  # .            "bg-gray-800 p-2 text-gray-400 hover:bg-gray-700 hover:text-white",
  #              "focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2",
  #              "focus:ring-offset-gray-800"]}
  #       aria-controls="mobile-menu"
  #       aria-expanded="false"
  #     >
  #       <span class="sr-only">Open main menu</span>
  #       <!-- Menu open: "hidden", Menu closed: "block"  -->
  #       <Heroicons.bars_3 outline class="hidden h-6 w-6" />
  #       <!-- Menu open: "block", Menu closed: "hidden"  -->
  #       <Heroicons.x_mark outline class="hidden h-6 w-6" />
  #     </button>
  #   </div>
  #   """
  # end
end

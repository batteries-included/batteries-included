defmodule ControlServerWeb.SidebarLayout do
  @moduledoc false
  use Phoenix.Component, global_prefixes: CommonUI.global_prefixes()
  use PetalComponents

  import CommonUI.Components.Brand

  attr :current_page, :atom,
    required: true,
    doc: "The current page. This will be used to highlight the current page in the menu."

  attr :main_menu_items, :list,
    default: [],
    doc: "The items that will be displayed in the main menu in the sidebar."

  attr :bottom_menu_items, :list,
    default: [],
    doc: "The items that will be displayed at the bottom of the sidebar menu."

  attr :home_path, :string,
    default: "/",
    doc: "The path to the home page. When a user clicks the logo, they will be taken to this path."

  attr :sidebar_bg_class, :string, default: "bg-white dark:bg-gray-darkest"
  attr :sidebar_border_class, :string, default: "border-gray-lighter dark:border-gray-darker"
  slot :inner_block, required: true, doc: "The main content of the page."

  slot :logo,
    doc: "Your logo. This will automatically sit within a link to the home_path attribute."

  def sidebar_layout(assigns) do
    ~H"""
    <div
      class="flex h-screen overflow-hidden bg-white dark:bg-gray-darkest"
      x-data="{sidebarOpen: false}"
    >
      <div class="relative z-40 lg:w-64">
        <div
          x-show="sidebarOpen"
          x-transition:enter="transition-opacity ease-linear duration-300"
          x-transition:enter-start="opacity-0"
          x-transition:enter-end="opacity-100"
          x-transition:leave="transition-opacity ease-linear duration-300"
          x-transition:leave-start="opacity-100"
          x-transition:leave-end="opacity-0"
          class="fixed inset-0 bg-gray-darkest/80"
        >
        </div>

        <div
          id="sidebar"
          class={[
            "absolute top-0 left-0 z-40 flex-shrink-0 w-64 h-full overflow-y-auto",
            "transition-transform duration-200 ease-in-out transform border-r no-scrollbar",
            "lg:static lg:left-auto lg:top-auto lg:translate-x-0 lg:overflow-y-auto",
            @sidebar_bg_class,
            @sidebar_border_class
          ]}
          x-bind:class="sidebarOpen ? 'translate-x-0' : '-translate-x-64'"
          @click.away="sidebarOpen = false"
          @keydown.escape.window="sidebarOpen = false"
          x-cloak
        >
          <div class="relative flex flex-col w-full h-full p-4 sidebar-background">
            <div class="flex items-center justify-between h-auto gap-2 px-3 pt-5 mb-10">
              <.a class="flex-1 block h-9" to={@home_path}>
                <.logo />
              </.a>
            </div>

            <div class="flex flex-col justify-between h-full">
              <.vertical_menu
                :if={@main_menu_items}
                menu_items={@main_menu_items}
                current_page={@current_page}
              />
              <.vertical_menu
                :if={@bottom_menu_items}
                menu_items={@bottom_menu_items}
                current_page={@current_page}
              />
            </div>
          </div>
        </div>
      </div>

      <.background_gradient_blur />

      <div class="relative flex flex-col flex-1 p-8 overflow-x-auto overflow-y-auto lg:pb-0">
        <div class="flex min-w-[68px] mb-6 lg:mb-0">
          <button
            class="text-gray-dark hover:text-gray-darker lg:hidden"
            @click.stop="sidebarOpen = !sidebarOpen"
            aria-controls="sidebar"
            x-bind:aria-expanded="sidebarOpen"
          >
            <span class="sr-only">
              Open sidebar
            </span>
            <.icon name={:bars_3} class="w-6 h-6 fill-current" />
          </button>
        </div>

        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  def background_gradient_blur(assigns) do
    ~H"""
    <svg
      class="absolute top-0 right-0"
      width="491"
      height="205"
      viewBox="0 0 491 205"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <g opacity="0.5" filter="url(#filter0_f_834_17481)">
        <circle class="fill-[#F0EDFF] dark:fill-[#5D5589]" cx="245.016" cy="-40.0562" r="149.016" />
      </g>
      <defs>
        <filter
          id="filter0_f_834_17481"
          x="0"
          y="-285.072"
          width="490.032"
          height="490.032"
          filterUnits="userSpaceOnUse"
          color-interpolation-filters="sRGB"
        >
          <feFlood flood-opacity="0" result="BackgroundImageFix" />
          <feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape" />
          <feGaussianBlur stdDeviation="48" result="effect1_foregroundBlur_834_17481" />
        </filter>
      </defs>
    </svg>

    <svg
      class="absolute top-0 right-0"
      width="497"
      height="272"
      viewBox="0 0 497 272"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <g opacity="0.44" filter="url(#filter0_f_834_17482)">
        <ellipse
          class="fill-[#FED8EB] dark:fill-[#4B2538]"
          cx="337.394"
          cy="-58.9357"
          rx="240.606"
          ry="234.064"
        />
      </g>
      <defs>
        <filter
          id="filter0_f_834_17482"
          x="0.787109"
          y="-389"
          width="673.213"
          height="660.129"
          filterUnits="userSpaceOnUse"
          color-interpolation-filters="sRGB"
        >
          <feFlood flood-opacity="0" result="BackgroundImageFix" />
          <feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape" />
          <feGaussianBlur stdDeviation="48" result="effect1_foregroundBlur_834_17482" />
        </filter>
      </defs>
    </svg>
    """
  end
end

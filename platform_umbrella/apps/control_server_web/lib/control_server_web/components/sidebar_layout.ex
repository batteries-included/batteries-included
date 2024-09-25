defmodule ControlServerWeb.SidebarLayout do
  @moduledoc false
  use Phoenix.Component

  import CommonUI.Components.Icon
  import CommonUI.Components.Logo
  import CommonUI.Components.TabBar

  alias Phoenix.LiveView.JS

  attr :current_page, :atom,
    default: nil,
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
    <div class="flex h-screen overflow-hidden bg-white dark:bg-gray-darkest">
      <div class="relative z-40 lg:w-64">
        <div
          class="fixed inset-0 bg-gray-darkest/80 hidden"
          id="sidebarInset"
          phx-click={hide_sidebar()}
        >
          <!-- This is the backdrop that will be
          shown when the sidebar is open. It's over
          the content when mobile sidebar is open -->
        </div>

        <div
          id="sidebar"
          class={[
            "absolute top-0 left-0 z-40 flex-shrink-0 w-64 h-full overflow-y-auto",
            "transition-transform duration-200 ease-in-out transform border-r no-scrollbar",
            "lg:static lg:left-auto lg:top-auto lg:translate-x-0 lg:overflow-y-auto",
            "-translate-x-64",
            @sidebar_bg_class,
            @sidebar_border_class
          ]}
          phx-window-keydown={hide_sidebar()}
          phx-key="Escape"
        >
          <div class="relative flex flex-col w-full h-full p-4 sidebar-background">
            <div class="flex items-center justify-between h-auto gap-2 px-3 pt-5 mb-10">
              <.link navigate={@home_path} class="flex-1 block h-9">
                <.logo variant="full" />
              </.link>
            </div>

            <nav class="flex flex-col justify-between h-full">
              <.tab_bar variant="navigation" class="flex-1">
                <:tab
                  :for={item <- @main_menu_items}
                  icon={item.icon}
                  navigate={item.path}
                  selected={item.type == @current_page}
                >
                  <%= item.name %>
                </:tab>
              </.tab_bar>

              <.tab_bar variant="navigation">
                <:tab
                  :for={item <- @bottom_menu_items}
                  icon={item.icon}
                  navigate={item.path}
                  selected={item.type == @current_page}
                >
                  <%= item.name %>
                </:tab>
              </.tab_bar>
            </nav>
          </div>
        </div>
      </div>

      <.background_gradient_blur />

      <div class="relative flex flex-col flex-1 p-8 overflow-auto">
        <div class="flex min-w-[68px] mb-6 lg:mb-0">
          <button
            class="text-gray-dark hover:text-gray-darker lg:hidden"
            aria-controls="sidebar"
            phx-click={show_sidebar()}
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

  defp show_sidebar(js \\ %JS{}) do
    js
    |> JS.add_class("translate-x-0", to: "#sidebar")
    |> JS.remove_class("-translate-x-64", to: "#sidebar")
    |> JS.remove_class("hidden", to: "#sidebarInset")
  end

  defp hide_sidebar(js \\ %JS{}) do
    js
    |> JS.remove_class("translate-x-0", to: "#sidebar")
    |> JS.add_class("-translate-x-64", to: "#sidebar")
    |> JS.add_class("hidden", to: "#sidebarInset")
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

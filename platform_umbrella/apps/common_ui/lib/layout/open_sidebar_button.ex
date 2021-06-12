defmodule CommonUI.Layout.OpenSidebarButton do
  use Surface.Component

  def render(assigns) do
    ~F"""
    <button
      type="button"
      class="px-4 text-gray-500 border-r border-gray-200 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-pink-500 md:hidden"
      x-on:click="menuOpen = true"
    >
      <span class="sr-only">Open sidebar</span>
      <!-- Heroicon name: outline/menu-alt-2 -->
      <svg
        class="w-6 h-6"
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        aria-hidden="true"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M4 6h16M4 12h16M4 18h7"
        />
      </svg>
    </button>
    """
  end
end

defmodule CommonUI.Layout.CloseSidebarButton do
  use Surface.Component

  def render(assigns) do
    ~F"""
    <button
      type="button"
      class="flex items-center justify-center w-12 h-12 rounded-full focus:outline-none focus:ring-2 focus:ring-white"
      x-on:click="menuOpen = false"
    >
      <!-- Heroicon name: outline/x -->
      <svg
        class="w-6 h-6 text-white"
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        aria-hidden="true"
      >
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
      </svg>
      <span class="sr-only">Close sidebar</span>
    </button>
    """
  end
end

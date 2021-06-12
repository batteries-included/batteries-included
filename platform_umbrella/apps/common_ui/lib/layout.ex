defmodule CommonUI.Layout do
  use Surface.Component

  alias CommonUI.Layout.CloseSidebarButton
  alias CommonUI.Layout.OpenSidebarButton

  slot(default, required: true)
  slot(main_menu)
  slot(mobile_menu)
  prop(bg_class, :string, default: "bg-astral-400")

  def render(assigns) do
    ~F"""
    <div class="flex h-screen overflow-hidden bg-gray-50" x-data="{menuOpen: false}">
      <!-- Narrow sidebar -->
      <div class={"hidden w-28 overflow-y-auto md:block #{@bg_class}"}>
        <div class="flex flex-col items-center w-full py-6">
          <div class="flex items-center flex-shrink-0">
            <img class="w-auto h-8" src="/images/logo.2.clip.png" alt="Batteries Included">
          </div>
          <div class={"flex-1 mt-6 w-full px-2 space-y-1 #{@bg_class}"}>
            <#slot name="main_menu" />
          </div>
        </div>
      </div>

      <!--
        Mobile menu

        Off-canvas menu for mobile, show/hide based on off-canvas menu state.
      -->
      <div
        class="fixed inset-0 z-40 flex md:hidden"
        role="dialog"
        aria-modal="true"
        x-show.transition="menuOpen"
      >
        <!--
          Off-canvas menu overlay, show/hide based on off-canvas menu state.
        -->
        <div
          class="fixed inset-0 bg-pink-500 bg-opacity-50"
          aria-hidden="true"
          x-on:click="menuOpen = false"
        />

        <!--
          Off-canvas menu, show/hide based on off-canvas menu state.
        -->
        <div class={"relative max-w-xs w-full pt-5 pb-4 flex-1 flex flex-col  #{@bg_class}"}>
          <!--
            Close button, show/hide based on off-canvas menu state.
          -->
          <div class="absolute right-0 p-1 top-1 -mr-14">
            <CloseSidebarButton />
          </div>
          <!-- Logo -->
          <div class="flex items-center flex-shrink-0 px-4">
            <img class="w-auto h-8" src="/images/logo.png" alt="Batteries Included">
          </div>

          <div class="flex-1 h-0 px-2 mt-5 overflow-y-auto">
            <nav class="flex flex-col h-full">
              <div class="space-y-1">
                <!-- Menu Items for mobile menu -->
                <#slot name="mobile_menu" />
              </div>
            </nav>
          </div>
        </div>

        <div class="flex-shrink-0 w-14" aria-hidden="true">
          <!-- Dummy element to force sidebar to shrink to fit close icon -->
        </div>
      </div>

      <!--
        Main content pane
      -->
      <div class="flex flex-col flex-1 overflow-hidden">
        <header class="w-full">
          <div class="relative z-10 flex flex-shrink-0 h-16 bg-white border-gray-200 shadow-sm">
            <OpenSidebarButton />
          </div>
        </header>

        <div class="flex items-stretch flex-1 overflow-hidden">
          <main class="flex-1 overflow-y-auto">
            <div class="px-4 pt-8 sm:px-6 lg:px-8">
              <#slot name="default" />
            </div>
          </main>
        </div>
      </div>
    </div>
    """
  end
end

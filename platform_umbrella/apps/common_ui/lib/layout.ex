defmodule CommonUI.Layout do
  use Surface.Component

  alias Surface.Components.Link

  require Logger

  slot default, required: true
  slot main_menu
  slot title
  prop bg_class, :string, default: "bg-white"

  prop logo_path, :string, default: "/"

  prop container_type, :atom, default: :default

  @default_container_class "flex-1 max-w-7xl sm:px-6 lg:px-8 py-10"
  @iframe_container_class "flex-1 py-0 px-0 w-full h-full"

  defp container_class(:iframe), do: @iframe_container_class

  defp container_class(:default) do
    @default_container_class
  end

  def render(assigns) do
    ~F"""
    <div
      class="flex flex-col min-h-screen justify-between bg-gray-50 pb-18 overflow-auto"
      x-data="{menuOpen: false}"
    >
      <header class="w-full bg-white h-16">
        <div class="flex max-w-7xl h-full">
          <Link to={@logo_path} class="my-auto mx-4">
            <img class="w-auto h-8" src="/images/logo.2.clip.png" alt="Batteries Included">
          </Link>
          <#slot name="title" />
          <h1 class="flex-grow px-5 text-2xl text-right text-gray-500 my-auto mx-6">Batteries Included</h1>
        </div>
      </header>
      <div class={container_class(@container_type)}>
        <#slot name="default" />
      </div>
    </div>
    <footer class="h-16 bg-white bottom-0 fixed inset-x-0 z-40">
      <div class="flex w-full">
        <#slot name="main_menu" />
      </div>
    </footer>
    """
  end
end

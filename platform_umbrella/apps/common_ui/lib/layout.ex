defmodule CommonUI.Layout do
  use Phoenix.Component

  use PetalComponents

  @default_container_class "flex-1 max-w-7xl sm:px-6 lg:px-8 pt-10 pb-20"
  @iframe_container_class "flex-1 py-0 px-0 w-full h-full"

  defp container_class(:iframe), do: @iframe_container_class

  defp container_class(:default) do
    @default_container_class
  end

  def title(assigns) do
    ~H"""
    <h2 class="my-auto ml-3 text-2xl font-bold leading-7 text-pink-500 sm:text-3xl sm:truncate">
      <%= render_slot(@inner_block) %>
    </h2>
    """
  end

  def menu_item(assigns) do
    ~H"""
    <.link
      link_type="live_redirect"
      to={"#{@to}"}
      class={
        [
          "group",
          "w-full",
          "p-3",
          "rounded-md",
          "flex",
          "flex-col",
          "items-center",
          "text-sm",
          "font-medium"
        ] ++ @class
      }
    >
      <%= render_slot(@inner_block) %>
      <span class="mt-2">
        <%= @name %>
      </span>
    </.link>
    """
  end

  def layout(assigns) do
    assigns = assign_defaults(assigns)

    ~H"""
    <div
      class="flex flex-col min-h-screen justify-between bg-gray-50 pb-18 overflow-auto"
      x-data="{menuOpen: false}"
    >
      <header class="w-full bg-white h-16">
        <div class="flex max-w-7xl h-full">
          <.link to={@logo_path} class="my-auto mx-4" link_type="live_redirect">
            <img class="w-auto h-8" src="/images/logo.2.clip.png" alt="Batteries Included" />
          </.link>
          <%= render_slot(@title) %>
          <h1 class="flex-grow px-5 text-2xl text-right text-gray-500 my-auto mx-6">
            Batteries Included
          </h1>
        </div>
      </header>
      <div class={container_class(@container_type)}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    <footer class="h-16 bg-white bottom-0 fixed inset-x-0 z-40">
      <div class="flex w-full">
        <%= render_slot(@main_menu) %>
      </div>
    </footer>
    """
  end

  defp assign_defaults(assigns) do
    assigns
    |> assign_new(:bg_class, fn -> "bg-white" end)
    |> assign_new(:logo_path, fn -> "/" end)
    |> assign_new(:container_type, fn -> :default end)
  end
end

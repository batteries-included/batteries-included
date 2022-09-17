defmodule CommonUI.Layout do
  use Phoenix.Component

  use PetalComponents

  @default_container_class "flex-1 max-w-7xl sm:px-6 lg:px-8 pt-10 pb-20 "
  @iframe_container_class "flex-1 py-0 px-0 w-full h-full "
  @menu_item_class "pt-1 text-sm font-medium "

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
    assigns =
      assigns
      |> assign_new(:base_class, fn -> @menu_item_class end)
      |> assign_new(:class, fn -> "" end)

    ~H"""
    <.link link_type="live_redirect" to={@to} class={@base_class <> " " <> @class}>
      <%= render_slot(@inner_block) %>
      <span class="mt-1">
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
          <%= if @title do %>
            <%= render_slot(@title) %>
          <% end %>
          <h1 class="flex-grow px-5 text-2xl text-right text-gray-500 my-auto mx-6">
            Batteries Included
          </h1>
          <%= if @user_menu do %>
            <%= render_slot(@user_menu) %>
          <% end %>
        </div>
      </header>
      <div class={container_class(@container_type)}>
        <%= if @inner_block do %>
          <%= render_slot(@inner_block) %>
        <% end %>
      </div>
    </div>
    <footer class="btm-nav">
      <%= if @main_menu do %>
        <%= render_slot(@main_menu) %>
      <% end %>
    </footer>
    """
  end

  defp assign_defaults(assigns) do
    assigns
    |> assign_new(:bg_class, fn -> "bg-white" end)
    |> assign_new(:logo_path, fn -> "/" end)
    |> assign_new(:container_type, fn -> :default end)
    |> assign_new(:inner_block, fn -> nil end)
    |> assign_new(:title, fn -> nil end)
    |> assign_new(:user_menu, fn -> nil end)
    |> assign_new(:main_menu, fn -> nil end)
  end
end

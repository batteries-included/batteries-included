defmodule HomeBaseWeb.PageHTML do
  use HomeBaseWeb, :html
  import HomeBaseWeb.TopMenuLayout

  def home(assigns) do
    ~H"""
    <.top_menu_layout title="Dashboard" page={:home}>
      <div class="rounded-lg bg-white px-5 py-6 shadow sm:px-6 h-[32rem]"></div>
    </.top_menu_layout>
    """
  end
end

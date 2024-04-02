defmodule HomeBaseWeb.LogoContainer do
  @moduledoc false

  use HomeBaseWeb, :html

  # atrr(:title, :string, required: true)

  def logo_container(assigns) do
    ~H"""
    <.flex column class="mx-auto max-w-2xl items-stretch">
      <div>
        <.logo class="w-40 mx-auto pb-12" />
      </div>
      <.h2>
        <%= @title %>
      </.h2>

      <%= render_slot(@inner_block) %>
    </.flex>
    """
  end
end

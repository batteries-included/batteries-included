defmodule CommonUI.Typogoraphy do
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]

  attr :class, :string, default: ""

  attr :base_class, :string,
    default: "text-4xl font-extrabold leading-7 text-pink-500 sm:text-3xl sm:truncate"

  slot(:inner_block, required: true)

  def h1(assigns) do
    ~H"""
    <h1 class={[@class, @base_class]}><%= render_slot(@inner_block) %></h1>
    """
  end

  attr :class, :string, default: ""
  attr :base_class, :string, default: "text-2xl sm:text-3xl font-bold leading-10 text-astral-500"
  slot(:inner_block, required: true)

  def h2(assigns) do
    ~H"""
    <h2 class={[@class, @base_class]}><%= render_slot(@inner_block) %></h2>
    """
  end

  attr :class, :string, default: ""
  attr :base_class, :string, default: "text-xl sm:text-2xl font-bold leading-6"
  slot(:inner_block, required: true)

  def h3(assigns) do
    ~H"""
    <h3 class={[@class, @base_class]}><%= render_slot(@inner_block) %></h3>
    """
  end
end

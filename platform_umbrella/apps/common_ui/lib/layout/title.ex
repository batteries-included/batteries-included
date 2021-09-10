defmodule CommonUI.Layout.Title do
  use Surface.Component, slot: "title"

  slot default, required: true

  def render(assigns) do
    ~F"""
    <h2 class="my-auto ml-3 text-2xl font-bold leading-7 text-pink-500 sm:text-3xl sm:truncate">
      <#slot name="default" />
    </h2>
    """
  end
end

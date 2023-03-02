defmodule CommonUI.Card do
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]
  import CommonUI.CSSHelpers
  import CommonUI.Typogoraphy

  attr :class, :string, default: nil
  slot :inner_block
  slot :title

  def card(assigns) do
    ~H"""
    <div class={
      build_class([
        "p-4 bg-white rounded-lg border border-gray-200 shadow-lg",
        "flex flex-col",
        "overflow-auto",
        @class
      ])
    }>
      <.h2 :if={@title != nil and @title != []}>
        <%= render_slot(@title) %>
      </.h2>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end

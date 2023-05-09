defmodule CommonUI.Card do
  use CommonUI.Component

  import CommonUI.Typogoraphy

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(id)

  slot :inner_block
  slot :title

  def card(assigns) do
    ~H"""
    <div
      class={
        build_class([
          "p-4 bg-white rounded-lg border border-gray-200 shadow-lg",
          "flex flex-col",
          @class
        ])
      }
      {@rest}
    >
      <.h2 :if={@title != nil and @title != []}>
        <%= render_slot(@title) %>
      </.h2>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end

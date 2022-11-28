defmodule Header do
  use Phoenix.Component

  slot(:inner_block, required: true)

  def simple(assigns) do
    ~H"""
    <h1><%= render_slot(@inner_block) %></h1>
    """
  end
end

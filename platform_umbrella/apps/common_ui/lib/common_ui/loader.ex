defmodule CommonUI.Loader do
  @moduledoc false
  use CommonUI.Component

  attr :class, :string, default: ""

  def loader(assigns) do
    ~H"""
    <div class={["mx-auto loader", @class]}>
      <span></span>
      <span></span>
      <span></span>
      <span></span>
    </div>
    """
  end
end

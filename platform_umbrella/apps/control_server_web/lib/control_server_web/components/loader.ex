defmodule ControlServerWeb.Loader do
  @moduledoc false
  use ControlServerWeb, :html

  attr :class, :string, default: ""

  @spec loader(any) :: Phoenix.LiveView.Rendered.t()
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

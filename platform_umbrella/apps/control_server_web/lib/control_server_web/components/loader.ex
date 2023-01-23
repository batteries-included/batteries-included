defmodule ControlServerWeb.Loader do
  use ControlServerWeb, :html

  attr :class, :string, default: ""

  @spec loader(any) :: Phoenix.LiveView.Rendered.t()
  def loader(assigns) do
    ~H"""
    <div class={build_class(["mx-auto loader", @class])}>
      <span></span>
      <span></span>
      <span></span>
      <span></span>
    </div>
    """
  end
end

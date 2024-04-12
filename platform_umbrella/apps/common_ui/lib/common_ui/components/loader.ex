defmodule CommonUI.Components.Loader do
  @moduledoc false
  use CommonUI, :component

  attr :fullscreen, :boolean, default: false
  attr :class, :any, default: nil

  def loader(%{fullscreen: true} = assigns) do
    ~H"""
    <div class="fixed inset-0 z-50">
      <div class="fixed inset-0 z-10 bg-white/60 dark:bg-gray-darkest-tint/80 backdrop-blur-sm transition-all" />

      <div class="flex items-center justify-center min-h-full">
        <.loader class={["z-20", @class]} />
      </div>
    </div>
    """
  end

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

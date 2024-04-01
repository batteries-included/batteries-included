defmodule CommonUI.Components.Video do
  @moduledoc false
  use CommonUI, :component

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(src allow allowfullscreen referrerpolicy)

  def video(assigns) do
    ~H"""
    <iframe class={["w-full aspect-video rounded-lg", @class]} frameborder="0" {@rest} />
    """
  end
end

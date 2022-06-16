defmodule ControlServerWeb.Live.Home do
  use ControlServerWeb, :live_view

  import ControlServerWeb.Layout
  alias CommonUI.Button

  def render(assigns) do
    ~H"""
    <.layout>
      Coming Soon
      <Button.button size={:sm} color={:link}>Testing</Button.button>
    </.layout>
    """
  end
end

defmodule ControlServerWeb.Live.Home do
  use ControlServerWeb, :live_view

  import ControlServerWeb.Layout
  alias CommonUI.Button

  @impl true
  def mount(_params, session, socket) do
    {:ok, assign_user_id(socket, session)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout user_id={@user_id}>
      Coming Soon
      <Button.button size={:sm} color={:link} link_type="a" to="/users/log_in">Log In</Button.button>
    </.layout>
    """
  end
end

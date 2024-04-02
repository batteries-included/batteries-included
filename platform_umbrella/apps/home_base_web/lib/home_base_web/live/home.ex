defmodule HomeBaseWeb.Live.Home do
  @moduledoc false
  use HomeBaseWeb, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    Coming Soon <%= @current_user.email %>
    """
  end
end

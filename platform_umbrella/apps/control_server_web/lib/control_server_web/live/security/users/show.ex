defmodule ControlServerWeb.Live.UserShow do
  use ControlServerWeb, :live_view
  import ControlServerWeb.LeftMenuLayout

  alias ControlServer.Accounts

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    user = Accounts.get_user!(id)

    {:noreply,
     socket
     |> assign(:id, id)
     |> assign(:user, user)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title><%= @user.email %></.title>
      </:title>
      <:left_menu>
        <.security_menu active="users" />
      </:left_menu>
    </.layout>
    """
  end
end

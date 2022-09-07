defmodule ControlServerWeb.Live.UserNew do
  use ControlServerWeb, :live_view

  import ControlServerWeb.Layout

  alias ControlServer.Accounts.User
  alias ControlServerWeb.Live.UserFormComponent

  @impl true
  def mount(_params, _session, socket) do
    user = %User{}
    changeset = User.registration_changeset(user, %{})

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_info({"user:save", %{"user" => user}}, socket) do
    new_path = Routes.user_show_path(ControlServerWeb.Endpoint, :index, user.id)

    {:noreply, push_redirect(socket, to: new_path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>New User</.title>
      </:title>
      <h1>New ControlServer User</h1>
      <div>
        <.live_component
          module={UserFormComponent}
          id="new-user-form"
          user={@user}
          changeset={@changeset}
          action={:new}
          save_target={self()}
        />
      </div>
    </.layout>
    """
  end
end

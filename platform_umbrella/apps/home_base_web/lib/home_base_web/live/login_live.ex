defmodule HomeBaseWeb.LoginLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  import Phoenix.Flash

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:form, to_form(%{}, as: :user))
     |> assign(:page_title, "Log in")}
  end

  def render(assigns) do
    ~H"""
    <.form for={@form} id="login-form" action={~p"/login"} class="mb-4">
      <.h2 class="mb-8">Log in to your account</.h2>

      <.fieldset flash={@flash}>
        <.input
          type="email"
          field={@form[:email]}
          placeholder="Email"
          value={get(@flash, :email)}
          autocomplete="username"
          autofocus
        />

        <.input
          type="password"
          field={@form[:password]}
          placeholder="Password"
          autocomplete="current-password"
        />

        <.input type="checkbox" field={@form[:remember_me]}>Keep me logged in</.input>

        <.button type="submit" variant="primary" icon={:arrow_right} icon_position={:right}>
          Log in
        </.button>
      </.fieldset>
    </.form>

    <div class="text-center">
      <p>
        Don't have an account?
        <.a navigate={~p"/signup"}>Sign up</.a>
      </p>

      <.a navigate={~p"/reset"}>
        Forgot your password?
      </.a>
    </div>
    """
  end
end

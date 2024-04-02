defmodule HomeBaseWeb.UserLoginLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  import HomeBaseWeb.LogoContainer

  def render(assigns) do
    ~H"""
    <.logo_container title="Log in to your account">
      <.form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
        <.flex column>
          <.input field={@form[:email]} type="email" label="Email" required />
          <.input field={@form[:password]} type="password" label="Password" required />

          <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
          <.button
            phx-disable-with="Signing in..."
            class="w-full"
            type="submit"
            variant="primary"
            icon_position={:right}
            icon={:arrow_right}
          >
            Sign in
          </.button>
        </.flex>
      </.form>

      <.a href={~p"/users/reset_password"} variant="styled">
        Forgot your password?
      </.a>

      <div class="text-center">
        Don't have an account?
        <.a navigate={~p"/users/register"} variant="styled">
          Sign up
        </.a>
        for an account now.
      </div>
    </.logo_container>
    """
  end

  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end

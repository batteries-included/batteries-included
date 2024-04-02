defmodule HomeBaseWeb.UserLoginLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <div class="text-center">
        Sign in to account
        Don't have an account?
        <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
          Sign up
        </.link>
        for an account now.
      </div>

      <.form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
        <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
          Forgot your password?
        </.link>
        <.button phx-disable-with="Signing in..." class="w-full" type="submit">
          Sign in <span aria-hidden="true">→</span>
        </.button>
      </.form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end

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
    <.simple_form
      for={@form}
      id="login-form"
      action={~p"/login"}
      title="Log in to your account"
      flash={@flash}
      class="mb-4"
    >
      <.input
        field={@form[:email]}
        type="email"
        placeholder="Email"
        value={get(@flash, :email)}
        autocomplete="username"
        autofocus
      />

      <.input
        field={@form[:password]}
        type="password"
        placeholder="Password"
        autocomplete="current-password"
      />

      <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />

      <.button type="submit" variant="primary" icon={:arrow_right} icon_position={:right}>
        Log in
      </.button>
    </.simple_form>

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

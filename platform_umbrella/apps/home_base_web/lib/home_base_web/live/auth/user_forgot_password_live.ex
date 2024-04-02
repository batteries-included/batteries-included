defmodule HomeBaseWeb.UserForgotPasswordLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  import HomeBaseWeb.LogoContainer

  alias HomeBase.Accounts

  def render(assigns) do
    ~H"""
    <.logo_container title="Forgot your password?">
      <div class="text-center">
        Forgot your password?
        We'll send a password reset link to your inbox
      </div>

      <.form for={@form} id="reset_password_form" phx-submit="send_email">
        <.flex column>
          <.input field={@form[:email]} type="email" placeholder="Email" required />
          <.button
            phx-disable-with="Sending..."
            class="w-full"
            type="submit"
            variant="dark"
            icon_position={:right}
            icon={:envelope}
          >
            Send password reset instructions
          </.button>
        </.flex>
      </.form>
    </.logo_container>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      # Don't error out no matter what just in case this is an enumeration attack
      case Accounts.deliver_user_reset_password_instructions(
             user,
             &url(~p"/users/reset_password/#{&1}")
           ) do
        _ -> nil
      end
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end

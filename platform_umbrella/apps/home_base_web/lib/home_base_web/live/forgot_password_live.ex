defmodule HomeBaseWeb.ForgotPasswordLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias HomeBase.Accounts

  on_mount {HomeBaseWeb.RequestURL, :default}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(form: to_form(%{}))
     |> assign(:page_title, "Forgot password")}
  end

  def handle_event("send", %{"email" => email}, socket) do
    # Don't error out no matter what just in case this is an enumeration attack
    if user = Accounts.get_user_by_email(email) do
      with {:ok, token} <- Accounts.get_user_reset_password_token(user),
           {:ok, _} <-
             %{to: email, url: socket.assigns.request_url <> ~p"/reset/#{token}"}
             |> HomeBaseWeb.ResetPasswordEmail.render()
             |> HomeBase.Mailer.deliver() do
        # No action needed here, the with statement is to appease dialyzer (-_-)
      else
        _ -> nil
      end
    end

    {:noreply,
     socket
     |> put_flash(:info, "Please check your email for instructions")
     |> redirect(to: ~p"/login")}
  end

  def render(assigns) do
    ~H"""
    <.simple_form
      for={@form}
      id="reset-password-form"
      phx-submit="send"
      title="Forgot your password?"
      flash={@flash}
      class="mb-4"
    >
      <p>We'll send a password reset link to your inbox.</p>

      <.input field={@form[:email]} type="email" placeholder="Email" autocomplete="email" autofocus />

      <.button type="submit" variant="primary" icon={:envelope} icon_position={:right}>
        Send reset instructions
      </.button>
    </.simple_form>

    <div class="text-center">
      Remembered your password?
      <.a navigate={~p"/login"}>Log in</.a>
    </div>
    """
  end
end

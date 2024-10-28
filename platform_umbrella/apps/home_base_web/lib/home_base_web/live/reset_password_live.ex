defmodule HomeBaseWeb.ResetPasswordLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias HomeBase.Accounts

  def mount(params, _session, socket) do
    socket = assign_user_and_token(socket, params)

    {:ok, assign(socket, :page_title, "Reset password")}
  end

  def handle_event("reset", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        # Do not log in the user after reset password to avoid a
        # leaked token giving the user access to the account.
        {:noreply,
         socket
         |> put_flash(:success, "Password successfully reset")
         |> redirect(to: ~p"/login")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  defp assign_user_and_token(socket, %{"token" => token}) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      form =
        user
        |> Accounts.change_user_password()
        |> to_form()

      assign(socket, form: form, user: user, token: token)
    else
      socket
      |> put_flash(:error, "Link is invalid or has expired")
      |> redirect(to: ~p"/login")
    end
  end

  def render(assigns) do
    ~H"""
    <.panel variant="shadowed" title="Reset your password" title_size="lg">
      <.form for={@form} id="reset-password-form" phx-change="validate" phx-submit="reset">
        <.fieldset flash={@flash}>
          <.badge>
            <:item label="Email"><%= @user.email %></:item>
          </.badge>

          <.input
            type="password"
            field={@form[:password]}
            placeholder="New password"
            autocomplete="new-password"
            autofocus
          />

          <.input
            type="password"
            field={@form[:password_confirmation]}
            placeholder="Retype password"
            autocomplete="new-password"
          />

          <.button type="submit" variant="primary">
            Reset Password
          </.button>
        </.fieldset>
      </.form>
    </.panel>
    """
  end
end

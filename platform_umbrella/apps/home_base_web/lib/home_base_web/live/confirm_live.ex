defmodule HomeBaseWeb.ConfirmLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias HomeBase.Accounts

  def mount(%{"token" => token}, _session, socket) do
    {:ok,
     socket
     |> assign(:token, token)
     |> assign(:page_title, "Confirm your account")}
  end

  def handle_event("confirm", _params, socket) do
    case Accounts.confirm_user(socket.assigns.token) do
      {:ok, _} ->
        # Do not log in the user after confirmation to avoid a
        # leaked token giving the user access to the account.
        if socket.assigns.current_user do
          {:noreply,
           socket
           |> put_flash(:global_success, "User confirmed successfully")
           |> redirect(to: ~p"/")}
        else
          {:noreply,
           socket
           |> put_flash(:success, "User confirmed successfully")
           |> redirect(to: ~p"/login")}
        end

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns.current_user do
          %{confirmed_at: confirmed_at} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: ~p"/")}

          nil ->
            {:noreply,
             socket
             |> put_flash(:error, "Link is invalid or it has expired")
             |> redirect(to: ~p"/login")}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <.panel variant="shadowed" title="Confirm your account" title_size="lg">
      <p class="mb-8">
        Thanks for signing up with Batteries Included, we're so excited to have you here!
        Please take a moment to confirm your email address by clicking on the button below.
      </p>

      <.button
        variant="primary"
        class="w-full"
        icon={:check_circle}
        icon_position={:right}
        phx-click="confirm"
      >
        Confirm your account
      </.button>
    </.panel>
    """
  end
end

defmodule HomeBaseWeb.ProfileLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias HomeBase.Accounts

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully")

        :error ->
          put_flash(socket, :error, "Link is invalid or it has expired")
      end

    {:ok, push_navigate(socket, to: ~p"/profile")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    {:ok,
     socket
     |> assign(:current_password, nil)
     |> assign(:email_form_current_password, nil)
     |> assign(:current_email, user.email)
     |> assign(:email_form, to_form(email_changeset))
     |> assign(:password_form, to_form(password_changeset))
     |> assign(:trigger_submit, false)
     |> assign(:confirmation_resent, false)
     |> assign(:page, :profile)
     |> assign(:page_title, "Profile")}
  end

  def handle_event("validate_email", %{"current_password" => password, "user" => user_params}, socket) do
    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", %{"current_password" => password, "user" => user_params}, socket) do
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        {:ok, _} =
          Accounts.deliver_user_update_email_instructions(
            applied_user,
            user.email,
            &url(~p"/profile/#{&1}")
          )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", %{"current_password" => password, "user" => user_params}, socket) do
    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", %{"current_password" => password, "user" => user_params}, socket) do
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        changeset = Accounts.change_user_password(user, user_params)

        {:noreply, assign(socket, password_form: to_form(changeset), trigger_submit: true)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("resend_confirm", _params, socket) do
    case Accounts.deliver_user_confirmation_instructions(socket.assigns.current_user, &url(~p"/confirm/#{&1}")) do
      {:ok, _} -> {:noreply, assign(socket, :confirmation_resent, true)}
      _ -> {:noreply, assign(socket, :confirmation_resent, false)}
    end
  end

  def render(assigns) do
    ~H"""
    <.h2>Your Profile</.h2>

    <.flash
      :if={!@current_user.confirmed_at}
      kind={:warning}
      variant="inline"
      class="inline-block mb-4"
    >
      <span>Your account still needs to be been confirmed!</span>

      <span :if={@confirmation_resent} class="opacity-50">
        Email resent
      </span>

      <.a :if={!@confirmation_resent} variant="styled" phx-click="resend_confirm">
        Resend confirmation email
      </.a>
    </.flash>

    <.grid columns={%{sm: 1, lg: 2, xl: 3}}>
      <.panel title="Change your email">
        <.simple_form
          for={@email_form}
          id="email-form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input field={@email_form[:email]} type="email" label="Email" autocomplete="email" />

          <.input
            field={@email_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            value={@email_form_current_password}
            autocomplete="password"
          />

          <.button type="submit" variant="dark">
            Save
          </.button>
        </.simple_form>
      </.panel>

      <.panel title="Change your password">
        <.simple_form
          for={@password_form}
          id="password-form"
          method="post"
          action={~p"/login?action=password_updated"}
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input field={@password_form[:email]} type="hidden" value={@current_email} />

          <.input
            field={@password_form[:password]}
            type="password"
            label="New password"
            autocomplete="new-password"
          />

          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Retype password"
            autocomplete="new-password"
          />

          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            autocomplete="password"
            value={@current_password}
          />

          <.button type="submit" variant="dark">
            Save
          </.button>
        </.simple_form>
      </.panel>
    </.grid>
    """
  end
end

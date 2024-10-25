defmodule HomeBaseWeb.SignupLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  import CommonCore.URLs

  alias CommonCore.Accounts.User
  alias HomeBase.Accounts

  on_mount {HomeBaseWeb.RequestURL, :default}

  def mount(params, _session, socket) do
    changeset =
      Accounts.change_user_registration(%User{
        email: params["email"]
      })

    {:ok,
     socket
     |> assign(trigger_submit: false)
     |> assign(:form, to_form(changeset))
     |> assign(:page_title, "Sign up")}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    with {:ok, user} <- Accounts.register_user(user_params),
         {:ok, token} <- Accounts.get_user_confirmation_token(user),
         {:ok, _} <-
           %{to: user.email, url: socket.assigns.request_url <> ~p"/confirm/#{token}"}
           |> HomeBaseWeb.WelcomeConfirmEmail.render()
           |> HomeBase.Mailer.deliver() do
      changeset = Accounts.change_user_registration(user)

      {:noreply, assign(socket, form: to_form(changeset), trigger_submit: true)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}

      _ ->
        {:noreply, put_flash(socket, :error, "Something went wrong, please try again.")}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_registration(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-wrap w-full justify-center gap-12 lg:gap-28">
      <.list variant="check" class="max-w-md self-center">
        <:item>Get started with a single command-line script</:item>
        <:item>Configure Kuburnetes installs with an easy UI</:item>
        <:item>Self-host your infrastructure on any cluster</:item>
        <:item>Manage your installations, teams, and billing</:item>
        <:item>Completely free to use for public beta</:item>
      </.list>

      <.panel variant="shadowed" title="Sign up for an account" title_size="lg">
        <.form
          for={@form}
          id="signup-form"
          method="post"
          action={~p"/login?action=registered"}
          phx-change="validate"
          phx-submit="save"
          phx-trigger-action={@trigger_submit}
        >
          <.fieldset flash={@flash}>
            <.input
              type="email"
              field={@form[:email]}
              placeholder="Email"
              autocomplete="email"
              autofocus
            />

            <.input
              type="password"
              field={@form[:password]}
              placeholder="Password"
              autocomplete="new-password"
            />

            <.input
              type="password"
              field={@form[:password_confirmation]}
              placeholder="Retype Password"
              autocomplete="new-password"
            />

            <.input type="checkbox" field={@form[:terms]}>
              I agree to the
              <.a href={"#{marketing_url()}/terms-service"} target="_blank">
                terms & conditions
              </.a>
            </.input>

            <.button type="submit" variant="primary" icon={:arrow_right} icon_position={:right}>
              Create account
            </.button>
          </.fieldset>
        </.form>

        <div class="text-center mt-4">
          Already have an account?
          <.a navigate={~p"/login"}>Log in</.a>
        </div>
      </.panel>
    </div>
    """
  end
end

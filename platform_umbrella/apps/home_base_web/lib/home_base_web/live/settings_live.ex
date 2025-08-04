defmodule HomeBaseWeb.SettingsLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias CommonCore.Teams.Team
  alias CommonCore.Teams.TeamRole
  alias HomeBase.Accounts
  alias HomeBase.Repo
  alias HomeBase.Teams

  on_mount {HomeBaseWeb.RequestURL, :default}

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :success, "Email changed successfully")

        :error ->
          put_flash(socket, :error, "Link is invalid or it has expired")
      end

    {:ok, push_navigate(socket, to: ~p"/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    # This prevents someone from manually changing the DOM events
    # to perform an admin action when they're not an admin.
    socket =
      attach_hook(socket, :check_admin, :handle_event, fn
        "save_role", _params, socket -> require_admin(socket)
        "update_role", _params, socket -> require_admin(socket)
        "delete_role", _params, socket -> require_admin(socket)
        "update_team", _params, socket -> require_admin(socket)
        "delete_team", _params, socket -> require_admin(socket)
        _event, _params, socket -> {:cont, socket}
      end)

    {:ok,
     socket
     |> assign(:current_password, nil)
     |> assign(:email_form_current_password, nil)
     |> assign(:current_email, user.email)
     |> assign(:email_form, to_form(email_changeset))
     |> assign(:password_form, to_form(password_changeset))
     |> assign(:trigger_submit, false)
     |> assign(:confirmation_resent, false)
     |> assign(:page, :settings)
     |> assign(:page_title, "Settings")
     |> maybe_assign_team()}
  end

  defp require_admin(socket) do
    if socket.assigns.current_role.is_admin do
      {:cont, socket}
    else
      {:halt, put_flash(socket, :global_error, "You don't have permission for that")}
    end
  end

  defp maybe_assign_team(%{assigns: %{current_role: %{team: team}}} = socket) do
    team_changeset = Team.changeset(team)
    role_changeset = TeamRole.changeset(%TeamRole{})

    %{roles: roles} = Teams.preload_team_roles(team, socket.assigns.current_user)

    socket
    |> assign(:roles, roles)
    |> assign(:team_form, to_form(team_changeset))
    |> assign(:role_form, to_form(role_changeset))
  end

  defp maybe_assign_team(socket), do: socket

  def handle_event("resend_confirm", _params, socket) do
    user = socket.assigns.current_user

    with {:ok, token} <- Accounts.get_user_confirmation_token(user),
         {:ok, _} <-
           %{to: user.email, url: socket.assigns.request_url <> ~p"/confirm/#{token}"}
           |> HomeBaseWeb.ConfirmEmail.render()
           |> HomeBase.Mailer.deliver() do
      {:noreply, assign(socket, :confirmation_resent, true)}
    else
      _ -> {:noreply, put_flash(socket, :global_error, "Could not resend confirmation email")}
    end
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

    with {:ok, applied_user} <- Accounts.apply_user_email(user, password, user_params),
         {:ok, token} <- Accounts.get_user_update_email_token(applied_user, user.email),
         {:ok, _} <-
           %{to: applied_user.email, url: socket.assigns.request_url <> ~p"/settings/#{token}"}
           |> HomeBaseWeb.ConfirmEmail.render()
           |> HomeBase.Mailer.deliver() do
      {:noreply,
       socket
       |> assign(email_form_current_password: nil)
       |> put_flash(:info, "A link to confirm your email change has been sent to the new address.")}
    else
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

  def handle_event("validate_team", %{"team" => params}, socket) do
    changeset =
      %Team{}
      |> Team.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :team_form, to_form(changeset))}
  end

  def handle_event("update_team", %{"team" => params}, socket) do
    case Teams.update_team(socket.assigns.current_role.team, params) do
      {:ok, team} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Team has been updated")
         |> redirect(to: ~p"/teams/#{team.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :team_form, to_form(changeset))}
    end
  end

  def handle_event("validate_role", %{"team_role" => params}, socket) do
    changeset =
      %TeamRole{}
      |> TeamRole.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :role_form, to_form(changeset))}
  end

  def handle_event("save_role", %{"team_role" => params}, socket) do
    team = socket.assigns.current_role.team

    with {:ok, role} <- Teams.create_team_role(team, params),
         {:ok, _} <- notify_user_of_role(role, team, socket.assigns.request_url) do
      role_changeset = TeamRole.changeset(%TeamRole{})

      {:noreply,
       socket
       |> assign(:roles, socket.assigns.roles ++ [role])
       |> assign(:role_form, to_form(role_changeset))}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :role_form, to_form(changeset))}

      _ ->
        {:noreply, put_flash(socket, :global_error, "Could not notify member")}
    end
  end

  def handle_event("update_role", %{"team_role" => %{"id" => id} = params}, socket) do
    role = Enum.find(socket.assigns.roles, &(&1.id == id))

    case Teams.update_team_role(role, params) do
      {:ok, role} ->
        # Replace the updated role in the assigns
        roles = Enum.map(socket.assigns.roles, &if(&1.id == id, do: role, else: &1))

        {:noreply,
         socket
         |> assign(:roles, roles)
         |> put_flash(:global_success, "Member has been updated")}

      _ ->
        {:noreply,
         socket
         |> assign(:roles, socket.assigns.roles)
         |> put_flash(:global_error, "Could not update member")}
    end
  end

  def handle_event("delete_role", %{"id" => id}, socket) do
    role = Enum.find(socket.assigns.roles, &(&1.id == id))

    with {:ok, _} <- Teams.delete_team_role(role),
         {:ok, _} <- notify_user_of_booted(role, socket.assigns.current_role.team) do
      roles = Enum.reject(socket.assigns.roles, &(&1.id == id))

      {:noreply,
       socket
       |> assign(:roles, roles)
       |> put_flash(:global_success, "Member has been removed")}
    else
      _ ->
        {:noreply, put_flash(socket, :global_error, "Could not remove member")}
    end
  end

  def handle_event("delete_team", _params, socket) do
    team = socket.assigns.current_role.team

    case Teams.soft_delete_team(team) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "#{team.name} has been deleted")
         |> redirect(to: ~p"/teams/personal")}

      {:error, changeset} ->
        # TODO: This is a weird way of handling constraint errors, come up with something better
        case Ecto.Changeset.traverse_errors(changeset, &elem(&1, 0)) do
          %{installations: _} -> {:noreply, put_flash(socket, :global_error, "Team still has installations")}
          _ -> {:noreply, put_flash(socket, :global_error, "Could not delete team")}
        end
    end
  end

  def handle_event("leave_team", _params, socket) do
    role = socket.assigns.current_role

    case Teams.delete_team_role(role) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "You left the #{role.team.name} team")
         |> redirect(to: ~p"/teams/personal")}

      {:error, :last_admin} ->
        {:noreply, put_flash(socket, :global_error, "Team must have at least one admin")}

      _ ->
        {:noreply, put_flash(socket, :global_error, "Could not leave team")}
    end
  end

  defp notify_user_of_role(%TeamRole{user: %{email: email}}, team, req_url) do
    %{to: email, team: team, url: req_url <> ~p"/installations"}
    |> HomeBaseWeb.TeamRoleEmail.render()
    |> HomeBase.Mailer.deliver()
  end

  defp notify_user_of_role(%TeamRole{invited_email: email}, team, req_url) do
    %{to: email, team: team, url: req_url <> ~p"/signup?#{[email: email]}"}
    |> HomeBaseWeb.TeamInvitedEmail.render()
    |> HomeBase.Mailer.deliver()
  end

  defp notify_user_of_booted(%{user_id: nil}, _team), do: {:ok, nil}

  defp notify_user_of_booted(%{user_id: _} = role, team) do
    role = Repo.preload(role, :user)

    %{to: role.user.email, team: team}
    |> HomeBaseWeb.TeamBootedEmail.render()
    |> HomeBase.Mailer.deliver()
  end

  def render(assigns) do
    ~H"""
    <.flash_group flash={@flash} />

    <.h2>Your Profile</.h2>

    <.alert :if={!@current_user.confirmed_at} variant="warning" class="inline-flex mb-4">
      <span>Your account still needs to be been confirmed.</span>

      <span :if={@confirmation_resent} class="opacity-50">
        Email resent
      </span>

      <.a :if={!@confirmation_resent} variant="underlined" phx-click="resend_confirm">
        Resend confirmation email
      </.a>
    </.alert>

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

    <div :if={@current_role} class="mt-8">
      <.h2>Your Team</.h2>

      <.grid :if={@current_role.is_admin} columns={%{sm: 1, lg: 2, xl: 3}}>
        <.form
          for={@team_form}
          id="update-team-form"
          phx-change="validate_team"
          phx-submit="update_team"
        >
          <.panel inner_class="flex flex-col gap-4">
            <.input field={@team_form[:name]} label="Team Name" autocomplete="organization" />

            <.input
              field={@team_form[:op_email]}
              label="Email Address"
              autocomplete="email"
              note="Optional. This is where we will send most operational emails."
            />

            <.button type="submit" variant="dark" class="w-full">Save</.button>
          </.panel>
        </.form>

        <.panel title="Members">
          <div
            :for={role <- @roles}
            class="flex gap-3 bg-gray-lightest dark:bg-gray-darkest dark:border dark:border-gray-darker-tint mb-3 px-3 py-1 rounded-md"
          >
            <div class="flex items-center gap-2 flex-1">
              {role.invited_email || role.user.email}

              <.badge :if={role.invited_email} label="pending" minimal />
              <.badge :if={role.id == @current_role.id} label="you" minimal />
            </div>

            <div :if={role.id != @current_role.id} class="flex items-center gap-4">
              <.form
                :let={f}
                for={role |> TeamRole.changeset() |> to_form()}
                id={"update-role-form-#{role.id}"}
                phx-change="update_role"
              >
                <.input field={f[:id]} type="hidden" />
                <.input field={f[:is_admin]} type="checkbox" label="Admin" />
              </.form>

              <.button
                variant="minimal"
                icon={:x_mark}
                phx-click="delete_role"
                phx-value-id={role.id}
                data-confirm={"Are you sure you want to remove #{role.invited_email || role.user.email} from the team?"}
              />
            </div>
          </div>

          <.form
            for={@role_form}
            id="new-role-form"
            phx-change="validate_role"
            phx-submit="save_role"
            class="flex flex-col gap-3 mt-8"
          >
            <div class="flex items-center justify-between gap-6">
              <div class="flex-1">
                <.input
                  field={@role_form[:invited_email]}
                  placeholder="Enter an email address"
                  autocomplete="off"
                />
              </div>

              <.input field={@role_form[:is_admin]} type="checkbox" label="Admin" />
            </div>

            <.button type="submit" variant="dark">Invite new member</.button>
          </.form>
        </.panel>

        <.panel title="Danger Zone">
          <p class="mb-6">
            Want to delete your team? All members will be removed.<br />
            <b>THIS CANNOT BE UNDONE!</b>
          </p>

          <.button
            variant="danger"
            phx-click="delete_team"
            data-confirm={"Are you sure you want to delete the #{@current_role.team.name} team?"}
            class="mr-4"
          >
            Delete Team
          </.button>

          <.button
            variant="secondary"
            phx-click="leave_team"
            data-confirm={"Are you sure you want to leave the #{@current_role.team.name} team?"}
          >
            Leave Team
          </.button>
        </.panel>
      </.grid>

      <div :if={!@current_role.is_admin}>
        <.grid columns={%{sm: 1, lg: 2, xl: 3}}>
          <.panel>
            <div class="mb-4">
              {@current_role.team.name}
            </div>

            <.button
              variant="secondary"
              phx-click="leave_team"
              data-confirm={"Are you sure you want to leave the #{@current_role.team.name} team?"}
            >
              Leave Team
            </.button>
          </.panel>
        </.grid>
      </div>
    </div>
    """
  end
end

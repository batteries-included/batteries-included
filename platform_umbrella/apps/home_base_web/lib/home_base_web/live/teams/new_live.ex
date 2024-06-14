defmodule HomeBaseWeb.TeamsNewLive do
  @moduledoc false

  use HomeBaseWeb, :live_view

  alias CommonCore.Teams.Team
  alias CommonCore.Teams.TeamRole
  alias HomeBase.Teams

  def mount(_params, _session, socket) do
    changeset = Team.changeset(%Team{roles: [empty_role()]})

    {:ok,
     socket
     |> assign(:page, :new_team)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("validate", %{"team" => params}, socket) do
    changeset =
      %Team{}
      |> Team.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"team" => params}, socket) do
    with {:ok, team} <- Teams.create_team(socket.assigns.current_user, params),
         {:ok, _} <- notify_users_of_role(team) do
      {:noreply,
       socket
       |> put_flash(:global_success, "Team created successfully")
       |> redirect(to: ~p"/teams/#{team.id}?redirect_to=/")}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        # Leave an empty role input to prevent the need for an extra click
        changeset =
          if Ecto.Changeset.get_field(changeset, :roles) == [] do
            Ecto.Changeset.put_change(changeset, :roles, [empty_role()])
          else
            changeset
          end

        {:noreply, assign(socket, :form, to_form(changeset))}

      _ ->
        {:noreply, put_flash(socket, :global_error, "Could not notify team members")}
    end
  end

  defp notify_users_of_role(team) do
    team.roles
    |> Enum.map(fn role ->
      # Send a different email to users that already have an account
      case role.user do
        %{email: email} ->
          HomeBaseWeb.TeamRoleEmail.render(%{to: email, team: team, url: url(~p"/installations")})

        _ ->
          HomeBaseWeb.TeamInvitedEmail.render(%{
            to: role.invited_email,
            team: team,
            url: url(~p"/signup?#{[email: role.invited_email]}")
          })
      end
    end)
    |> HomeBase.Mailer.deliver_many()
  end

  def render(assigns) do
    ~H"""
    <.form for={@form} id="new-team-form" phx-change="validate" phx-submit="save">
      <div class="flex items-center justify-between mb-2">
        <.h2>Create a new team</.h2>

        <.button type="submit" variant="primary" icon={:arrow_right} icon_position={:right}>
          Create Team
        </.button>
      </div>

      <.grid columns={%{sm: 1, lg: 2}}>
        <div>
          <.panel inner_class="flex flex-col gap-4">
            <.input field={@form[:name]} label="Team Name" autocomplete="organization" />

            <.input
              field={@form[:op_email]}
              label="Email Address"
              autocomplete="email"
              note="Optional. This is where we will send most operational emails."
            />
          </.panel>
        </div>

        <.panel title="Invite Members">
          <div class="flex flex-col gap-3">
            <.inputs_for :let={f} field={@form[:roles]}>
              <input type="hidden" name="team[sort_roles][]" value={f.index} />

              <div class="flex items-center justify-between gap-6">
                <div class="flex-1">
                  <.input
                    field={f[:invited_email]}
                    placeholder="Enter an email address"
                    autocomplete="off"
                  />
                </div>

                <.input field={f[:is_admin]} type="checkbox" label="Admin" />

                <.button
                  variant="minimal"
                  icon={:x_mark}
                  name="team[drop_roles][]"
                  value={f.index}
                  phx-click={JS.dispatch("change")}
                />
              </div>
            </.inputs_for>
          </div>

          <input type="hidden" name="team[drop_roles][]" />

          <.button
            variant="minimal"
            icon={:plus}
            class="mt-4"
            name="team[sort_roles][]"
            value="new"
            phx-click={JS.dispatch("change")}
          >
            Invite another member
          </.button>

          <%= if assigns[:inner_block], do: render_slot(@inner_block) %>
        </.panel>
      </.grid>
    </.form>
    """
  end

  defp empty_role, do: %TeamRole{invited_email: "", is_admin: false}
end

defmodule HomeBaseWeb.DashboardLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias CommonCore.Installation
  alias HomeBase.Accounts
  alias HomeBase.CustomerInstalls

  on_mount {HomeBaseWeb.RequestURL, :default}

  def mount(_params, _session, socket) do
    total_teams = CustomerInstalls.count_teams(socket.assigns.current_user)
    total_installations = CustomerInstalls.count_installations(socket.assigns.current_user)
    recent_installations = CustomerInstalls.list_recent_installations(socket.assigns.current_user)

    grouped_installations = group_installations_by_team(recent_installations)

    {:ok,
     socket
     |> assign(:page, :dashboard)
     |> assign(:page_title, "Dashboard")
     |> assign(:total_teams, total_teams)
     |> assign(:total_installations, total_installations)
     |> assign(:recent_installations, recent_installations)
     |> assign(:grouped_installations, grouped_installations)
     |> assign(:confirmation_resent, false)}
  end

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

  def render(assigns) do
    ~H"""
    <div class="flex flex-wrap items-center justify-between gap-4 mb-4 lg:mb-6">
      <div class="flex flex-wrap gap-4">
        <.badge label="Teams" value={@total_teams} />
        <.badge label="Installations" value={@total_installations} />
      </div>
    </div>

    <.grid columns={[sm: 1, md: 2, lg: 3]}>
      <.panel :if={@total_installations <= 0} title="First Steps">
        <p class="mb-6">
          Welcome to Batteries Included! Ready to get started with a new installation? You can run it on your local machine or on a Kubernetes cluster.
        </p>

        <.button variant="primary" link={~p"/installations/new"}>Create an installation</.button>
      </.panel>

      <.panel :if={@current_user.roles == []} title="Working with others?">
        <p class="mb-6">
          Create a team that others can be invited to as an admin or member. Each person can see and manage the team's installations, and each team is billed individually.
        </p>

        <.button variant="secondary" link={~p"/teams/new"}>
          Create a team
        </.button>
      </.panel>

      <.panel :if={!@current_user.confirmed_at} title="Confirm Your Account">
        <p class="mb-6">
          Your account still needs to be been confirmed. Please check your email for a confirmation link.
        </p>

        <.button disabled={@confirmation_resent} variant="secondary" phx-click="resend_confirm">
          {if @confirmation_resent, do: "Sent!", else: "Resend Confirmation Link"}
        </.button>
      </.panel>

      <.panel :if={@total_installations > 0}>
        <div :for={{team_name, installations} <- @grouped_installations} class="mb-6 last:mb-0">
          <h3 class="text-lg font-semibold mb-3 text-gray-900">{team_name}</h3>
          <.table
            id={"recent-installations-#{team_name |> String.replace(" ", "-") |> String.downcase()}"}
            rows={installations}
            row_click={&JS.navigate(show_installation_url(&1))}
          >
            <:col :let={installation} label="Slug">{installation.slug}</:col>
            <:col :let={installation} label="Provider">{installation.kube_provider}</:col>
            <:col :let={installation} label="Usage">{installation.usage}</:col>

            <:action :let={installation}>
              <.button
                variant="minimal"
                link={~p"/installations/#{installation}"}
                icon={:eye}
                id={"show_installation_" <> installation.id}
              />

              <.tooltip target_id={"show_installation_" <> installation.id}>
                Show Installation
              </.tooltip>
            </:action>
          </.table>
        </div>
      </.panel>

      <.panel :if={@total_installations > 0} title="Keep Going">
        <p class="mb-6">
          Are you ready to expand your infrastructure even more? Get started with another installation and keep this thing going.
        </p>

        <.button variant="secondary" link={~p"/installations/new"}>Create a new installation</.button>
      </.panel>
    </.grid>
    """
  end

  defp show_installation_url(%Installation{} = installation) do
    ~p"/teams/#{installation.team_id || "personal"}?redirect_to=/installations/#{installation.id}"
  end

  defp group_installations_by_team(installations) do
    installations
    |> Enum.group_by(&team_name/1)
    |> Enum.sort_by(fn {team_name, _} -> team_name end)
  end

  defp team_name(installation) do
    if installation.team, do: installation.team.name, else: "Personal"
  end
end

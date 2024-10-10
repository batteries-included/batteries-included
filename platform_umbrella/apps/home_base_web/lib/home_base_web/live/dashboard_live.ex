defmodule HomeBaseWeb.DashboardLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias CommonCore.Installation
  alias HomeBase.CustomerInstalls

  def mount(_params, _session, socket) do
    total_teams = CustomerInstalls.count_teams(socket.assigns.current_user)
    total_installations = CustomerInstalls.count_installations(socket.assigns.current_user)
    recent_installations = CustomerInstalls.list_recent_installations(socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page, :dashboard)
     |> assign(:page_title, "Dashboard")
     |> assign(:total_teams, total_teams)
     |> assign(:total_installations, total_installations)
     |> assign(:recent_installations, recent_installations)}
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

      <.panel :if={@total_installations > 0} title="Recent Installations">
        <.table
          id="recent-installations"
          rows={@recent_installations}
          row_click={&JS.navigate(show_installation_url(&1))}
        >
          <:col :let={installation} label="Slug"><%= installation.slug %></:col>
          <:col :let={installation} label="Team">
            <%= if installation.team, do: installation.team.name, else: "Personal" %>
          </:col>

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
end

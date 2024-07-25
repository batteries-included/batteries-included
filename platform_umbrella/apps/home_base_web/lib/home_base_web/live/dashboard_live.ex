defmodule HomeBaseWeb.DashboardLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias HomeBase.CustomerInstalls
  alias HomeBaseWeb.UserAuth

  def mount(_params, _session, socket) do
    owner = UserAuth.current_team_or_user(socket)
    total_installations = CustomerInstalls.count_installations(owner)

    {:ok,
     socket
     |> assign(:page, :dashboard)
     |> assign(:page_title, "Dashboard")
     |> assign(:total_installations, total_installations)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-wrap items-center justify-between gap-4 mb-4 lg:mb-6">
      <div class="flex flex-wrap gap-4">
        <.badge label="Installations" value={@total_installations} />
      </div>
    </div>

    <.grid columns={[sm: 1, md: 2, lg: 3]}>
      <div :if={@total_installations <= 0 || @current_user.roles == []}>
        <.panel title="Get Started">
          <.light_text>
            Welcome to Batteries Included! Here are a few steps to help you get started:
          </.light_text>

          <.todo_list class="mt-6">
            <.todo_list_item completed={@total_installations > 0} navigate={~p"/installations/new"}>
              Start a new installation
            </.todo_list_item>

            <.todo_list_item
              :if={!@current_role}
              completed={@current_user.roles != []}
              navigate={~p"/teams/new"}
            >
              Create a team
            </.todo_list_item>
          </.todo_list>
        </.panel>
      </div>

      <div>
        <.panel title="Graph 1">
          <.chart
            id="graph2-chart"
            data={%{datasets: [%{label: "Placeholder", data: [10, 5, 1, 2]}]}}
            options={%{plugins: %{legend: %{display: false}}}}
            class="size-60 max-w-full m-auto"
          />
        </.panel>
      </div>

      <div>
        <.panel title="Graph 2">
          <.chart
            id="graph1-chart"
            data={%{datasets: [%{label: "Placeholder", data: [1, 2, 3]}]}}
            options={%{plugins: %{legend: %{display: false}}}}
            class="size-60 max-w-full m-auto"
          />
        </.panel>
      </div>
    </.grid>
    """
  end
end

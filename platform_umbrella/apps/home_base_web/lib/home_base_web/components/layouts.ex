defmodule HomeBaseWeb.Layouts do
  @moduledoc false
  use HomeBaseWeb, :html

  alias CommonCore.Accounts.User

  attr :page_title, :string, default: nil
  attr :inner_content, :any

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
        <meta name="csrf-token" content={get_csrf_token()} />

        <title :if={!@page_title}>Batteries Included</title>
        <.live_title :if={@page_title} suffix=" · Batteries Included">
          <%= @page_title %>
        </.live_title>

        <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
        <script phx-track-static defer type="text/javascript" src={~p"/assets/app.js"} />
      </head>
      <body class="antialiased font-sans font-normal leading-loose text-gray-darkest">
        <%= @inner_content %>
      </body>
    </html>
    """
  end

  attr :flash, :map
  attr :current_user, User
  attr :inner_content, :any

  def auth(assigns) do
    ~H"""
    <.flash_group flash={@flash} global />

    <.alert
      type="fixed"
      variant="disconnected"
      phx-connected={hide_alert()}
      phx-disconnected={show_alert()}
      autoshow={false}
    />

    <div class="flex items-center justify-center min-h-screen background-gradient">
      <div class="flex flex-col items-center gap-12 p-12 w-full">
        <.logo class="w-36" />

        <div class="w-full max-w-md bg-white shadow-2xl shadow-gray/30 rounded-lg p-6 lg:p-10">
          <%= @inner_content %>
        </div>

        <.button
          variant="minimal"
          icon={:arrow_left}
          link="https://www.batteriesincl.com"
          link_type="external"
        >
          Back to home
        </.button>
      </div>
    </div>
    """
  end

  attr :flash, :map
  attr :current_user, User
  attr :page, :atom, default: nil
  attr :inner_content, :any

  def app(assigns) do
    ~H"""
    <.flash_group flash={@flash} global />

    <.alert
      type="fixed"
      variant="disconnected"
      phx-connected={hide_alert()}
      phx-disconnected={show_alert()}
      autoshow={false}
    />

    <div class="flex flex-col h-screen">
      <div class="flex items-center justify-between relative header-gradient px-8 border-b border-b-gray-lighter">
        <.logo variant="full" class="my-3" />

        <div class="flex items-center gap-8">
          <.button variant={@page != :dashboard && "minimal"} icon={:chart_pie} link={~p"/"}>
            Dashboard
          </.button>

          <.button
            variant={@page != :installations && "minimal"}
            icon={:command_line}
            link={~p"/installations"}
          >
            Installations
          </.button>

          <div>
            <.dropdown id="main-dropdown">
              <:trigger>
                <.button
                  variant="secondary"
                  icon={:chevron_down}
                  icon_position={:right}
                  class="!min-w-0"
                >
                  <%= if @current_role, do: @current_role.team.name, else: @current_user.email %>
                </.button>
              </:trigger>

              <.dropdown_link
                :if={@current_user.roles != []}
                icon={:arrow_path}
                phx-click={
                  hide_dropdown("main-dropdown", :slide_x) |> show_dropdown("team-dropdown", :slide_x)
                }
              >
                Switch Team
              </.dropdown_link>

              <.dropdown_link icon={:plus_circle} navigate={~p"/teams/new"}>
                New Team
              </.dropdown_link>

              <.dropdown_hr />

              <.dropdown_link
                icon={:cog_6_tooth}
                navigate={~p"/settings"}
                selected={@page == :settings}
              >
                Settings
              </.dropdown_link>

              <.dropdown_link
                icon={:arrow_right_start_on_rectangle}
                href={~p"/logout"}
                method="delete"
              >
                Log out
              </.dropdown_link>
            </.dropdown>

            <.dropdown id="team-dropdown">
              <.dropdown_link :if={@current_role} href={~p"/teams/personal"}>
                Back to personal
              </.dropdown_link>

              <.dropdown_hr :if={@current_role} />

              <.dropdown_link
                :for={%{team: team} <- @current_user.roles}
                href={~p"/teams/#{team.id}"}
                selected={@current_role && @current_role.team_id == team.id}
              >
                <%= team.name %>
              </.dropdown_link>
            </.dropdown>
          </div>
        </div>
      </div>

      <div class="block relative p-8 flex-1 overflow-auto">
        <%= @inner_content %>
      </div>
    </div>
    """
  end
end

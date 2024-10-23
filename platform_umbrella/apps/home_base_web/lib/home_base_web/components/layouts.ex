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
      <body class="antialiased font-sans font-normal leading-loose text-gray-darkest dark:text-gray-lighter">
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

        <div class="w-full max-w-md bg-white dark:bg-gray-darkest shadow-2xl shadow-gray/30 dark:shadow-black/40 rounded-lg p-6 lg:p-10">
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
    assigns =
      if assigns[:current_role] do
        assign(assigns, :current_entity, assigns.current_role.team.name)
      else
        assign(assigns, :current_entity, assigns.current_user.email)
      end

    ~H"""
    <.flash_group flash={@flash} global />

    <.alert
      type="fixed"
      variant="disconnected"
      phx-connected={hide_alert()}
      phx-disconnected={show_alert()}
      autoshow={false}
    />

    <div class="flex flex-col h-screen background-gradient">
      <div class={[
        "flex items-center justify-between relative px-5 m-4 lg:m-6 rounded-lg",
        "bg-white dark:bg-gray-darkest border border-gray-lighter dark:border-gray-darker"
      ]}>
        <.link navigate={~p"/"}>
          <.logo variant="full" class="my-2" />
        </.link>

        <div class="flex items-center gap-8">
          <.button
            variant={@page != :dashboard && "minimal"}
            icon={:chart_pie}
            link={~p"/"}
            class="hidden lg:flex"
          >
            Dashboard
          </.button>

          <.button
            variant={@page != :installations && "minimal"}
            icon={:command_line}
            link={~p"/installations"}
            class="hidden lg:flex"
          >
            Installations
          </.button>

          <div>
            <.dropdown id="main-dropdown" class="mt-4 lg:mt-6">
              <:trigger>
                <.button variant="icon_bordered" icon={:bars_3} class="lg:hidden !min-w-0" />

                <.button
                  variant="minimal"
                  icon={if @current_role, do: :users, else: :user}
                  class="hidden lg:flex"
                >
                  <div class="flex items-center">
                    <%= @current_entity %>
                    <.icon name={:chevron_down} class="size-7" mini />
                  </div>
                </.button>
              </:trigger>

              <div class={[
                "px-4 py-3 font-semibold whitespace-nowrap text-ellipsis overflow-hidden lg:hidden",
                "border-b border-b-gray-lighter dark:border-b-gray-darker",
                "bg-gray-lightest dark:bg-gray-darkest-tint",
                "text-gray-light dark:text-gray-dark"
              ]}>
                <%= @current_entity %>
              </div>

              <.dropdown_link
                :if={@current_user.roles != []}
                icon={:arrow_path}
                phx-click={
                  hide_dropdown("main-dropdown", :slide_x) |> show_dropdown("team-dropdown", :slide_x)
                }
              >
                Switch Team
              </.dropdown_link>

              <.dropdown_link
                icon={:plus_circle}
                navigate={~p"/teams/new"}
                selected={@page == :new_team}
              >
                New Team
              </.dropdown_link>

              <.dropdown_hr />

              <.dropdown_link
                selected={@page == :dashboard}
                icon={:chart_pie}
                navigate={~p"/"}
                class="lg:hidden"
              >
                Dashboard
              </.dropdown_link>

              <.dropdown_link
                selected={@page == :installations}
                icon={:command_line}
                navigate={~p"/installations"}
                class="lg:hidden"
              >
                Installations
              </.dropdown_link>

              <.dropdown_link
                icon={:cog_6_tooth}
                navigate={~p"/settings"}
                selected={@page == :settings}
              >
                Settings
              </.dropdown_link>

              <.dropdown_link
                icon={:question_mark_circle}
                navigate={~p"/help"}
                selected={@page == :help}
              >
                Get Help
              </.dropdown_link>

              <.dropdown_link
                icon={:arrow_right_start_on_rectangle}
                href={~p"/logout"}
                method="delete"
              >
                Log out
              </.dropdown_link>
            </.dropdown>

            <.dropdown id="team-dropdown" class="mt-4 lg:mt-6">
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

      <div class="block relative px-4 lg:px-6 flex-1 overflow-auto">
        <%= @inner_content %>
      </div>
    </div>

    <.link
      :if={@page != :help}
      navigate={~p"/help"}
      class="fixed bottom-8 right-8 size-16 hover:opacity-80 invisible lg:visible"
    >
      <span class="absolute top-2 left-2 size-12 z-4 rounded-full bg-white shadow-xl" />
      <.icon name={:question_mark_circle} class="absolute size-16 z-5 text-secondary" solid />
    </.link>
    """
  end
end

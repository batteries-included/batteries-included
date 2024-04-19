defmodule HomeBaseWeb.Layouts do
  @moduledoc false
  use HomeBaseWeb, :html

  alias HomeBase.Accounts.User

  attr :page_title, :string, default: nil
  slot :inner_content

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
  slot :inner_content

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
  attr :page_group, :atom, default: nil
  slot :inner_content

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

    <.flex class="relative header-gradient items-center justify-between px-8 border-b border-b-gray-lighter">
      <.logo variant="full" class="my-3" />

      <nav role="navigation" class="flex gap-8">
        <.nav_item icon={:chart_pie} navigate={~p"/"} selected={@page == :dashboard}>
          Dashboard
        </.nav_item>

        <.nav_item
          icon={:command_line}
          navigate={~p"/installations"}
          selected={@page == :installations}
        >
          Installations
        </.nav_item>

        <.nav_item navigate={~p"/profile"} icon={:user_circle} selected={@page == :profile}>
          Profile
        </.nav_item>

        <.nav_item href={~p"/logout"} icon={:arrow_right_start_on_rectangle} method="delete">
          Log out
        </.nav_item>
      </nav>
    </.flex>

    <div class="block relative min-h-screen p-8">
      <%= @inner_content %>
    </div>
    """
  end

  attr :selected, :boolean, default: false
  attr :icon, :atom, required: true
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href method navigate)
  slot :inner_block, required: true

  defp nav_item(assigns) do
    ~H"""
    <.link
      class={[
        "flex items-center gap-2 text-sm font-semibold hover:text-primary",
        @selected && "text-primary",
        @class
      ]}
      {@rest}
    >
      <.icon name={@icon} class="size-5" />
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end
end

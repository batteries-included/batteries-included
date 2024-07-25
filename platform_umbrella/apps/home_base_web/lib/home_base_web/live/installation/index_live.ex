defmodule HomeBaseWeb.InstallationLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias HomeBase.CustomerInstalls
  alias HomeBaseWeb.UserAuth

  def mount(_params, _session, socket) do
    owner = UserAuth.current_team_or_user(socket)
    installations = CustomerInstalls.list_installations(owner)

    {:ok,
     socket
     |> assign(:page, :installations)
     |> assign(:page_title, "Installations")
     |> assign(:installations, installations)}
  end

  def render(assigns) do
    ~H"""
    <div :if={@installations == []} class="flex items-center justify-center min-h-full">
      <div class="text-center">
        <.icon name={:command_line} class="size-60 m-auto text-primary opacity-15" />

        <p class="text-gray-light text-lg font-medium mb-12">
          You don't have any installations.
        </p>

        <.button variant="primary" link={~p"/installations/new"}>
          Get Started
        </.button>
      </div>
    </div>

    <div :if={@installations != []}>
      <div class="flex items-center justify-between mb-2">
        <.h2>Installations</.h2>

        <.button variant="dark" icon={:plus} link={~p"/installations/new"}>
          New Installation
        </.button>
      </div>

      <.panel>
        <.table
          id="installations"
          rows={@installations}
          row_click={&JS.navigate(~p"/installations/#{&1}")}
        >
          <:col :let={installation} label="ID"><%= installation.id %></:col>
          <:col :let={installation} label="Slug"><%= installation.slug %></:col>

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
    </div>
    """
  end
end

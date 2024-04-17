defmodule HomeBaseWeb.InstallationLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias HomeBase.CustomerInstalls

  def mount(_params, _session, socket) do
    installations = CustomerInstalls.list_installations()

    {:ok, assign(socket, :installations, installations)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(:page, :installations)
     |> assign(:page_title, "Installations")}
  end

  def render(assigns) do
    ~H"""
    <div :if={@installations == []} class="">
      <div class="text-center">
        <.icon solid name={:bolt} class="size-60 m-auto text-primary opacity-10" />

        <p class="text-gray-light text-lg font-medium mb-16">
          You don't have any installations yet.
        </p>

        <.button variant="primary" link={~p"/installations/new"}>
          Get Started
        </.button>
      </div>
    </div>

    <div :if={@installations != []}>
      <div class="flex items-center justify-between">
        <.h2>Installations</.h2>

        <.button variant="dark" icon={:bolt} link={~p"/installations/new"}>
          New Installation
        </.button>
      </div>

      <.table
        id="installations"
        rows={@installations}
        row_click={&JS.navigate(~p"/installations/#{&1}")}
      >
        <:col :let={installation} label="Id"><%= installation.id %></:col>
        <:col :let={installation} label="Slug"><%= installation.slug %></:col>
        <:action :let={installation}>
          <div class="sr-only">
            <.a navigate={~p"/installations/#{installation}"}>Show</.a>
          </div>
          <.a navigate={~p"/installations/#{installation}"}>Edit</.a>
        </:action>
      </.table>
    </div>
    """
  end
end

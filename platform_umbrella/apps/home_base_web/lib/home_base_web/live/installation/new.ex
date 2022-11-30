defmodule HomeBaseWeb.Live.InstallationNew do
  use HomeBaseWeb, :live_view

  import HomeBaseWeb.TopMenuLayout

  alias HomeBase.ControlServerClusters.Installation
  alias HomeBase.ControlServerClusters

  alias HomeBaseWeb.Live.Installations.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    installation = %Installation{}
    changeset = ControlServerClusters.change_installation(installation)

    {:ok,
     socket
     |> assign(:installation, installation)
     |> assign(:changeset, changeset)}
  end

  def update(%{installation: installation} = assigns, socket) do
    changeset = ControlServerClusters.change_installation(installation)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_info({"installation:save", %{"installation" => installation}}, socket) do
    new_path = ~p"/installations/#{installation}/show"

    {:noreply, push_redirect(socket, to: new_path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.top_menu_layout page={:installations} title="New Installation">
      <.live_component
        module={FormComponent}
        id="new-installation-form"
        installation={@installation}
        action={:new}
        save_target={self()}
      />
    </.top_menu_layout>
    """
  end
end

defmodule HomeBaseWeb.Live.InstallationNew do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias CommonCore.Installation
  alias HomeBase.CustomerInstalls
  alias HomeBaseWeb.Live.Installations.FormComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    installation = %Installation{}
    changeset = CustomerInstalls.change_installation(installation)

    {:ok,
     socket
     |> assign(:installation, installation)
     |> assign(:changeset, changeset)}
  end

  def update(%{installation: installation} = assigns, socket) do
    changeset = CustomerInstalls.change_installation(installation)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveView
  def handle_info({"installation:save", %{"installation" => installation}}, socket) do
    new_path = ~p"/installations/#{installation}/show"

    {:noreply, push_redirect(socket, to: new_path)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.live_component
      module={FormComponent}
      id="new-installation-form"
      installation={@installation}
      action={:new}
      save_target={self()}
    />
    """
  end
end

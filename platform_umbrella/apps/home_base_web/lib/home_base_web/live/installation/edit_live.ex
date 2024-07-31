defmodule HomeBaseWeb.InstallationEditLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias CommonCore.Installation
  alias HomeBase.CustomerInstalls
  alias HomeBaseWeb.UserAuth

  def mount(%{"id" => id}, _session, socket) do
    owner = UserAuth.current_team_or_user(socket)
    installation = CustomerInstalls.get_installation!(id, owner)
    changeset = CustomerInstalls.change_installation(installation)

    {:ok,
     socket
     |> assign(:page, :installations)
     |> assign(:page_title, "Edit Installation")
     |> assign(:installation, installation)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("validate", %{"installation" => params}, socket) do
    changeset =
      socket.assigns.installation
      |> Installation.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"installation" => params}, socket) do
    case CustomerInstalls.update_installation(socket.assigns.installation, params) do
      {:ok, installation} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Installation saved")
         |> push_navigate(to: ~p"/installations/#{installation}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def render(assigns) do
    ~H"""
    <.form for={@form} id="edit-installation-form" phx-change="validate" phx-submit="save">
      <div class="flex items-center justify-between mb-2">
        <.h2>Edit Installation</.h2>

        <.button type="submit" variant="primary" icon={:arrow_right} icon_position={:right}>
          Save Installation
        </.button>
      </div>

      <.grid columns={[sm: 1, lg: 2]}>
        <.panel>
          <.input field={@form[:slug]} label="Installation Name" placeholder="Choose a name" />
        </.panel>
      </.grid>
    </.form>
    """
  end
end

defmodule HomeBaseWeb.InstallationNewLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias CommonCore.Installation
  alias HomeBase.CustomerInstalls
  alias HomeBaseWeb.UserAuth

  def mount(_params, _session, socket) do
    owner = UserAuth.current_team_or_user(socket)
    installations = CustomerInstalls.list_installations(owner)
    changeset = CustomerInstalls.change_installation(%Installation{})

    {:ok,
     socket
     |> assign(:page, :installations)
     |> assign(:page_title, "Installations")
     |> assign(:installations, installations)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("validate", %{"installation" => params}, socket) do
    changeset =
      %Installation{}
      |> Installation.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"installation" => params}, socket) do
    owner = UserAuth.current_team_or_user(socket)
    owner_key = if socket.assigns.current_role, do: "team_id", else: "user_id"
    params = Map.put(params, owner_key, owner.id)

    case CustomerInstalls.create_installation(params) do
      {:ok, installation} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Installation created successfully")
         |> push_navigate(to: ~p"/installations/#{installation}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def render(assigns) do
    ~H"""
    <.form for={@form} id="new-installation-form" phx-change="validate" phx-submit="save">
      <div class="flex items-center justify-between mb-2">
        <.h2>Create a new installation</.h2>

        <.button type="submit" variant="primary" icon={:arrow_right} icon_position={:right}>
          Create Installation
        </.button>
      </div>

      <.grid columns={%{sm: 1, lg: 2}}>
        <div>
          <.panel inner_class="flex flex-col gap-4">
            <.input field={@form[:slug]} label="Slug" placeholder="Choose a slug" />

            <.input
              field={@form[:usage]}
              type="select"
              label="How will this installation be used?"
              placeholder="Select usage type"
              options={Installation.usage_options()}
            />
          </.panel>
        </div>

        <.panel inner_class="flex flex-col gap-4">
          <.input
            field={@form[:kube_provider]}
            type="select"
            label="Where will this be installed?"
            placeholder="Select provider"
            options={Installation.provider_options()}
          />

          <.input
            field={@form[:default_size]}
            type="select"
            label="Default Size"
            options={Installation.size_options()}
          />
        </.panel>
      </.grid>
    </.form>
    """
  end
end

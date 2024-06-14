defmodule HomeBaseWeb.InstallationLive do
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
    <div :if={@installations == []} class="flex items-center justify-center min-h-full">
      <div class="text-center">
        <.icon name={:command_line} class="size-60 m-auto text-primary opacity-15" />

        <p class="text-gray-light text-lg font-medium mb-12">
          You don't have any installations.
        </p>

        <.button variant="primary" phx-click={show_modal("new-installation")}>
          Get Started
        </.button>
      </div>
    </div>

    <div :if={@installations != []}>
      <div class="flex items-center justify-between mb-2">
        <.h2>Installations</.h2>

        <.button variant="dark" icon={:plus} phx-click={show_modal("new-installation")}>
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

    <.modal id="new-installation">
      <:title>Start New Install</:title>

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:slug]} label="Slug" placeholder="Choose a slug" />

        <.input
          field={@form[:usage]}
          type="select"
          label="How will this installation be used?"
          placeholder="Select usage type"
          options={Installation.usage_options()}
        />

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

        <.input field={@form[:sso_enabled]} type="switch" label="Use Single Sign On" />

        <.input
          :if={@form[:sso_enabled].value}
          field={@form[:initial_oauth_email]}
          placeholder="Initial OAuth Email"
        />

        <:actions>
          <.button variant="primary" type="submit">Start</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end
end

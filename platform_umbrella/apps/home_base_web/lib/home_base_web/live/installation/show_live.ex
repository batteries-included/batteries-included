defmodule HomeBaseWeb.InstallationShowLive do
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
     |> assign(:page_title, installation.slug)
     |> assign(:installation, installation)
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
    case CustomerInstalls.update_installation(socket.assigns.installation, params) do
      {:ok, installation} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Installation updated successfully")
         |> push_navigate(to: ~p"/installations/#{installation}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("delete", _params, socket) do
    case CustomerInstalls.delete_installation(socket.assigns.installation) do
      {:ok, _} ->
        {:noreply, push_navigate(socket, to: ~p"/installations")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-6">
      <.h2><%= @installation.slug %></.h2>

      <div>
        <.button variant="icon" icon={:pencil} phx-click={show_modal("edit-installation")} />

        <.button
          variant="icon"
          icon={:trash}
          phx-click="delete"
          data-confirm={"Are you sure you want to delete the #{@installation.slug} installation?"}
        />
      </div>
    </div>

    <.grid columns={%{md: 1, lg: 2}}>
      <.panel variant="gray">
        <.data_list>
          <:item title="Usage"><%= @installation.usage %></:item>
          <:item title="Provider"><%= @installation.kube_provider %></:item>
          <:item title="Default Size"><%= @installation.default_size %></:item>
          <:item title="Created"><%= @installation.inserted_at %></:item>
        </.data_list>
      </.panel>
    </.grid>

    <.modal id="edit-installation">
      <:title>Edit Installation</:title>

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
          field={@form[:initial_oauth_email]}
          class={@form[:sso_enabled].value != "on" && "hidden"}
          placeholder="Initial OAuth Email"
        />

        <:actions>
          <.button variant="primary" type="submit">Save</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end
end

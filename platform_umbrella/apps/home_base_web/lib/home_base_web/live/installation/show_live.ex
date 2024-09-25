defmodule HomeBaseWeb.InstallationShowLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias CommonCore.Installation
  alias HomeBase.CustomerInstalls
  alias HomeBaseWeb.InstallationNewLive
  alias HomeBaseWeb.UserAuth

  on_mount {HomeBaseWeb.RequestURL, :default}

  def mount(%{"id" => id}, _session, socket) do
    owner = UserAuth.current_team_or_user(socket)
    installation = CustomerInstalls.get_installation!(id, owner)
    provider = provider_label(installation.kube_provider)
    changeset = CustomerInstalls.change_installation(installation)

    {:ok,
     socket
     |> assign(:page, :installations)
     |> assign(:page_title, installation.slug)
     |> assign(:installation, installation)
     |> assign(:provider, provider)
     |> assign(:installed?, !CommonCore.JWK.has_private_key?(installation.control_jwk))
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

  def provider_label(provider) do
    CommonCore.Installs.Options.providers()
    |> Enum.find(&(elem(&1, 1) == provider))
    |> elem(0)
    |> Atom.to_string()
  end

  def render(%{live_action: :success} = assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-full">
      <h2 class="text-4xl font-bold mb-12">Installation Created 🎉</h2>

      <.panel class="mb-8">
        <p class="leading-6 mb-4">
          To download and install the Batteries Included control server in <%= @provider %>, run the script below.
        </p>
        <!-- TODO: update script src to actual installation script -->
        <.script
          src={"#{@request_scheme}://#{@request_authority}/installations/#{@installation.id}/script"}
          class="mt-4 mb-8"
        />
        <.markdown content={explanation(@installation)} />
      </.panel>

      <.button variant="primary" link={~p"/"} icon={:arrow_right} icon_position={:right}>
        Continue to Dashboard
      </.button>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-2">
      <.h2><%= @installation.slug %></.h2>

      <div>
        <.button variant="icon" icon={:pencil} link={~p"/installations/#{@installation}/edit"} />

        <.button
          variant="icon"
          icon={:trash}
          phx-click="delete"
          data-confirm={"Are you sure you want to delete the #{@installation.slug} installation?"}
        />
      </div>
    </div>

    <.grid columns={%{md: 1, lg: 2}}>
      <.panel :if={!@installed?} title="Installation Instructions">
        <p class="leading-6 mb-4">
          We havn't heard from your installation yet! To download and install the Batteries Included control server in <%= @provider %>, run the script below.
        </p>
        <!-- TODO: update script src to actual installation script -->
        <.script
          src={"#{@request_scheme}://#{@request_authority}/installations/#{@installation.id}/script"}
          class="mb-8"
        />
        <.markdown content={explanation(@installation)} />
      </.panel>

      <.panel title="Details">
        <.data_list>
          <:item title="Usage"><%= @installation.usage %></:item>
          <:item title="Provider"><%= @installation.kube_provider %></:item>
          <:item title="Default Size"><%= @installation.default_size %></:item>
          <:item title="Created"><%= @installation.inserted_at %></:item>
        </.data_list>
      </.panel>

      <div :if={@installed?} class="flex flex-col gap-4">
        <!-- TODO: Link to installation's control server -->
        <.a variant="bordered" href={~p"/"}>Control Server</.a>
      </div>
    </.grid>
    """
  end

  defp explanation(installation) do
    """
    ## What will this do?

    #{InstallationNewLive.explanation_more(installation.usage, installation.kube_provider)}
    """
  end
end

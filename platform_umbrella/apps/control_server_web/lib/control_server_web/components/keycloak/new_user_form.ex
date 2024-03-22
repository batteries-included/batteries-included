defmodule ControlServerWeb.Keycloak.NewUserForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias CommonCore.OpenApi.KeycloakAdminSchema.UserRepresentation
  alias KubeServices.Keycloak.UserManager

  @impl Phoenix.LiveComponent
  def mount(socket) do
    user = Map.get(socket.assigns, :user, UserRepresentation.new!(%{}))

    {:ok,
     socket
     |> assign_api_error(nil)
     |> assign_new_url(nil)
     |> assign_form(changeset_from_user(user))}
  end

  @impl Phoenix.LiveComponent
  def update(%{user: user} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset_from_user(user))}
  end

  defp changeset_from_user(user) when is_struct(user) do
    UserRepresentation.changeset(UserRepresentation.new!(%{}), Map.from_struct(user))
  end

  defp changeset_from_user(user) do
    UserRepresentation.changeset(UserRepresentation.new!(%{}), user)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_new_url(socket, url) do
    assign(socket, :new_url, url)
  end

  defp assign_api_error(socket, error) do
    assign(socket, :api_error, error)
  end

  # This function UserManager to keycloak and sets the results into assigns.
  defp send_create(realm, user_params, socket) do
    case UserManager.create(realm, user_params) do
      {:ok, url} ->
        {:noreply, assign_new_url(socket, url)}

      {:error, err} ->
        {:noreply, assign_api_error(socket, inspect(err))}
    end
  end

  defp validation_changeset(user, params) when is_struct(user) do
    user
    |> UserRepresentation.changeset(params)
    |> Map.put(:action, :validate)
  end

  defp validation_changeset(user, params) when is_map(user) do
    user
    |> UserRepresentation.new!()
    |> UserRepresentation.changeset(params)
    |> Map.put(:action, :validate)
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"user_representation" => user_params} = _params, socket) do
    changeset = validation_changeset(socket.assigns.user, user_params)
    {:noreply, socket |> assign_form(changeset) |> assign_api_error(nil)}
  end

  def handle_event("save", %{"user_representation" => user_params} = _params, socket) do
    changeset = validation_changeset(socket.assigns.user, user_params)

    case Ecto.Changeset.apply_action(changeset, :update) do
      {:ok, user} ->
        send_create(socket.assigns.realm, user, socket)

      {:error, err_change} ->
        {:noreply, assign_form(socket, err_change)}
    end
  end

  @impl Phoenix.LiveComponent
  @spec render(map) :: Phoenix.LiveView.Rendered.t()
  def render(%{} = assigns) do
    ~H"""
    <div id={@id}>
      <.flex column>
        <.h2>New User</.h2>
        <div :if={@api_error != nil} class="text-warning-darker text-xxl font-bold">
          <%= @api_error %>
        </div>
        <div :if={@new_url != nil} class="text-xxl font-semibold">
          New User Created with<.a href={@new_url} variant="styled">Keycloak admin console here</.a>.
        </div>
        <.form
          :if={@new_url == nil}
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <.input field={@form[:email]} label="Email" placeholder="douglas.engelbart@gmail.com" />
          <.input field={@form[:username]} label="Username" />
          <.input field={@form[:enabled]} label="Enabled" type="checkbox" />

          <.button variant="primary" type="submit" phx-disable-with="Saving...">Save</.button>
        </.form>
      </.flex>
    </div>
    """
  end
end

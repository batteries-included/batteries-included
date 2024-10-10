defmodule ControlServerWeb.Keycloak.NewUserForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias CommonCore.OpenAPI.KeycloakAdminSchema.UserRepresentation
  alias KubeServices.Keycloak.UserManager

  @impl Phoenix.LiveComponent
  def mount(socket) do
    user = Map.get(socket.assigns, :user, UserRepresentation.new!(%{}))

    {:ok,
     socket
     |> assign_api_error(nil)
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

  defp assign_api_error(socket, error) do
    case error do
      %{body: body} ->
        error_message = Map.get(body, "errorMessage", "Something went wrong")
        assign(socket, :api_error, error_message)

      _ ->
        assign(socket, :api_error, nil)
    end
  end

  defp send_create(realm, user_params, make_admin, socket) do
    case UserManager.create(realm, user_params) do
      {:ok, user_id} ->
        send(self(), {:user_created, user_id})
        maybe_make_admin(socket, realm, user_id, make_admin)

      {:error, err} ->
        {:noreply, assign_api_error(socket, err)}
    end
  end

  defp maybe_make_admin(socket, _, _, false), do: {:noreply, socket}

  defp maybe_make_admin(socket, realm_name, user_id, true) do
    case UserManager.make_realm_admin(realm_name, user_id) do
      :ok ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :global_error, reason)}
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
    make_admin = Map.get(user_params, "make_admin") == "true"

    case Ecto.Changeset.apply_action(changeset, :update) do
      {:ok, user} ->
        send_create(socket.assigns.realm, user, make_admin, socket)

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
        <.alert :if={@api_error} variant="error">
          <%= @api_error %>
        </.alert>

        <.simple_form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself}>
          <.input field={@form[:email]} label="Email" />
          <.input field={@form[:username]} label="Username" />
          <.input field={@form[:enabled]} type="switch" label="Enabled" />
          <.input field={@form[:make_admin]} type="switch" label="Realm Admin" />

          <.alert>You'll receive a temporary password in the next step.</.alert>

          <:actions>
            <.button variant="primary" type="submit" phx-disable-with="Creating...">
              Create User
            </.button>
          </:actions>
        </.simple_form>
      </.flex>
    </div>
    """
  end
end

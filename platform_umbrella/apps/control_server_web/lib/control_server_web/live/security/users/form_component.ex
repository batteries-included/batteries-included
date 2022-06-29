defmodule ControlServerWeb.Live.UserFormComponent do
  use ControlServerWeb, :live_component

  alias CommonUI.Form
  alias ControlServer.Accounts
  alias ControlServer.Accounts.User

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:save_info, fn -> "user:save" end)
     |> assign_new(:save_target, fn -> nil end)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"user" => user_params} = _args,
        %{assigns: %{user: user}} = socket
      ) do
    changeset = user |> User.registration_changeset(user_params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, user_params)
  end

  defp save_user(socket, user_params) do
    case Accounts.register_user(user_params) do
      {:ok, new_user} ->
        {:noreply,
         socket
         |> put_flash(:info, "New user created successfully")
         |> send_info(socket.assigns.save_target, new_user)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp send_info(socket, nil, _user), do: {:noreply, socket}

  defp send_info(socket, target, user) do
    send(target, {socket.assigns.save_info, %{"user" => user}})
    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-10">
      <.form
        let={f}
        for={@changeset}
        id="user-form"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <div class="grid grid-cols-1 mt-6 gap-y-6 gap-x-4">
          <Form.text_input form={f} field={:email} phx_debounce="blur" placeholder="Email" />
          <Form.text_input form={f} field={:password} phx_debounce="blur" placeholder="Password" />
        </div>
        <div class="grid grid-cols-1 mt-6 gap-y-6 gap-x-4 sm:grid-cols-2">
          <.button type="submit" phx_disable_with="Saving…" class="sm:col-span-2">
            Save
          </.button>
        </div>
      </.form>
    </div>
    """
  end
end

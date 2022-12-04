defmodule HomeBaseWeb.Live.Installations.FormComponent do
  use HomeBaseWeb, :live_component

  alias HomeBase.ControlServerClusters

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:save_info, fn -> "installation:save" end)
     |> assign_new(:save_target, fn -> nil end)}
  end

  @impl Phoenix.LiveComponent
  def update(%{installation: installation} = assigns, socket) do
    changeset = ControlServerClusters.change_installation(installation)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"installation" => installation_params}, socket) do
    changeset =
      socket.assigns.installation
      |> ControlServerClusters.change_installation(installation_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"installation" => installation_params}, socket) do
    save_installation(socket, socket.assigns.action, installation_params)
  end

  defp save_installation(socket, :edit, installation_params) do
    case ControlServerClusters.update_installation(
           socket.assigns.installation,
           installation_params
         ) do
      {:ok, updated_installation} ->
        {:noreply,
         socket
         |> put_flash(:info, "Installation updated successfully")
         |> send_info(socket.assigns.save_target, updated_installation)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_installation(socket, :new, installation_params) do
    case ControlServerClusters.create_installation(installation_params) do
      {:ok, new_installation} ->
        {:noreply,
         socket
         |> put_flash(:info, "Installation created successfully")
         |> send_info(socket.assigns.save_target, new_installation)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp send_info(socket, target, installation) do
    send(target, {socket.assigns.save_info, %{"installation" => installation}})
    socket
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        :let={f}
        for={@changeset}
        id="installation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={{f, :slug}} type="text" label="slug" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Installation</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end

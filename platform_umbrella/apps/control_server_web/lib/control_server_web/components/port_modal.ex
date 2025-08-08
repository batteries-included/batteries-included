defmodule ControlServerWeb.PortModal do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias CommonCore.Port
  alias CommonCore.Protocol
  alias Ecto.Changeset

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(%{port: port, idx: idx, update_func: update_func, id: id} = _assigns, socket) do
    {:ok,
     socket
     |> assign_id(id)
     |> assign_idx(idx)
     |> assign_port(port)
     |> assign_changeset(Port.changeset(port, %{}))
     |> assign_update_func(update_func)}
  end

  defp assign_id(socket, id) do
    assign(socket, id: id)
  end

  defp assign_idx(socket, idx) do
    assign(socket, idx: idx)
  end

  defp assign_update_func(socket, update_func) do
    assign(socket, update_func: update_func)
  end

  defp assign_port(socket, port) do
    assign(socket, port: port)
  end

  defp assign_changeset(socket, changeset) do
    assign(socket, changeset: changeset, form: to_form(changeset))
  end

  @impl Phoenix.LiveComponent
  def handle_event("cancel", _, %{assigns: %{update_func: update_func}} = socket) do
    update_func.(nil, nil)
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate_port", %{"port" => params}, socket) do
    changeset =
      socket.assigns.port
      |> Port.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_changeset(socket, changeset)}
  end

  def handle_event(
        "save_port",
        %{"port" => params},
        %{assigns: %{port: port, idx: idx, update_func: update_func}} = socket
      ) do
    changeset =
      port
      |> Port.changeset(params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      new_port = Changeset.apply_changes(changeset)

      update_func.(new_port, idx)
    end

    {:noreply, assign_changeset(socket, changeset)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.form
        for={@form}
        id="port-form"
        phx-change="validate_port"
        phx-submit="save_port"
        phx-target={@myself}
      >
        <.modal show size="lg" id={"#{@id}-modal"} on_cancel={JS.push("cancel", target: @myself)}>
          <:title>Port</:title>

          <.fieldset>
            <.field>
              <:label>Name</:label>
              <.input field={@form[:name]} autofocus />
            </.field>

            <.field>
              <:label>Port</:label>
              <.input field={@form[:number]} />
            </.field>

            <.field>
              <:label>Protocol</:label>
              <.input field={@form[:protocol]} type="select" options={Protocol.options()} />
            </.field>
          </.fieldset>

          <:actions cancel="Cancel">
            <.button variant="primary" type="submit" phx-disable-with="Saving...">Save</.button>
          </:actions>
        </.modal>
      </.form>
    </div>
    """
  end
end

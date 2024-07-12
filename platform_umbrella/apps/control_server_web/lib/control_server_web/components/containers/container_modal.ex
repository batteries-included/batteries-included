defmodule ControlServerWeb.Containers.ContainerModal do
  @moduledoc false

  use ControlServerWeb, :live_component

  alias CommonCore.Containers.Container
  alias Ecto.Changeset

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign_new(socket, :target, fn -> nil end)}
  end

  @impl Phoenix.LiveComponent
  def update(
        %{container: container, idx: idx, container_field_name: cfn, update_func: update_func, id: id} = _assigns,
        socket
      ) do
    {:ok,
     socket
     |> assign_id(id)
     |> assign_idx(idx)
     |> assign_container(container)
     |> assign_container_field_name(cfn)
     |> assign_changeset(Container.changeset(container, %{}))
     |> assign_update_func(update_func)}
  end

  defp assign_id(socket, id) do
    assign(socket, id: id)
  end

  defp assign_idx(socket, idx) do
    assign(socket, idx: idx)
  end

  defp assign_container(socket, container) do
    assign(socket, container: container)
  end

  defp assign_container_field_name(socket, cfn) do
    assign(socket, container_field_name: cfn)
  end

  defp assign_changeset(socket, changeset) do
    assign(socket, changeset: changeset, form: to_form(changeset))
  end

  defp assign_update_func(socket, update_func) do
    assign(socket, update_func: update_func)
  end

  @impl Phoenix.LiveComponent
  def handle_event("cancel", _, %{assigns: %{update_func: update_func, container_field_name: cfn}} = socket) do
    update_func.(nil, nil, cfn)
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate_container", %{"container" => params}, socket) do
    changeset = Container.changeset(socket.assigns.container, params)
    {:noreply, assign_changeset(socket, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "save_container",
        %{"container" => params},
        %{assigns: %{container: container, idx: idx, container_field_name: cfn, update_func: update_func}} = socket
      ) do
    # Create a new changeset for the container
    changeset = Container.changeset(container, params)

    if changeset.valid? do
      # Get the resulting container from the changeset
      container = Changeset.apply_changes(changeset)
      update_func.(container, idx, cfn)
    end

    {:noreply, assign_changeset(socket, changeset)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id="container-form"
        phx-change="validate_container"
        phx-submit="save_container"
        phx-target={@myself}
      >
        <.modal show size="lg" id={"#{@id}-modal"} on_cancel={JS.push("cancel", target: @myself)}>
          <:title>Container</:title>

          <.flex column>
            <.input label="Name" field={@form[:name]} autofocus placeholder="Name" />
            <.input label="Image" field={@form[:image]} placeholder="Image" />
            <.input
              label="Command (optional)"
              name="container[command][]"
              value={(@form.data.command || []) |> List.first(nil)}
              placeholder="/bin/true"
            />
          </.flex>

          <:actions cancel="Cancel">
            <.button variant="primary" type="submit" phx-disable-with="Saving...">Save</.button>
          </:actions>
        </.modal>
      </.form>
    </div>
    """
  end
end

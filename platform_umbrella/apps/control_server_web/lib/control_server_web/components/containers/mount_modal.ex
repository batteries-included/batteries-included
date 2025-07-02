defmodule ControlServerWeb.Containers.MountModal do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias CommonCore.Containers.Mount
  alias Ecto.Changeset

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(%{mount: mount, idx: idx, update_func: update_func, volumes: volumes, id: id} = _assigns, socket) do
    {:ok,
     socket
     |> assign(volumes: volumes)
     |> assign_id(id)
     |> assign_idx(idx)
     |> assign_mount(mount)
     |> assign_changeset(Mount.changeset(mount, %{}))
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

  defp assign_mount(socket, mount) do
    assign(socket, mount: mount)
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
  def handle_event("validate_mount", %{"mount" => params}, socket) do
    changeset =
      socket.assigns.mount
      |> Mount.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_changeset(socket, changeset)}
  end

  def handle_event(
        "save_mount",
        %{"mount" => params},
        %{assigns: %{mount: mount, idx: idx, update_func: update_func}} = socket
      ) do
    changeset =
      mount
      |> Mount.changeset(params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      new_mount = Changeset.apply_changes(changeset)

      update_func.(new_mount, idx)
    end

    {:noreply, assign_changeset(socket, changeset)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.form
        for={@form}
        id="mount-form"
        phx-change="validate_mount"
        phx-submit="save_mount"
        phx-target={@myself}
      >
        <.modal show size="lg" id={"#{@id}-modal"} on_cancel={JS.push("cancel", target: @myself)}>
          <:title>Volume Mount</:title>

          <.fieldset>
            <.field>
              <:label>Volume Name</:label>
              <.input
                type="select"
                field={@form[:volume_name]}
                autofocus
                options={Enum.map(@volumes, & &1.name)}
              />
            </.field>
            <.field>
              <:label>Mount Path</:label>
              <.input field={@form[:mount_path]} />
            </.field>
            <.field>
              <:label>Read Only?</:label>
              <.input type="checkbox" field={@form[:read_only]} />
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
